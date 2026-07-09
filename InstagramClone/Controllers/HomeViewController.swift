import UIKit
import FirebaseFirestore
import FirebaseAuth

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts: [Post] = []
    private var listener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        startListeningForPosts()
        
        self.navigationItem.hidesBackButton = true
        self.tabBarController?.navigationItem.hidesBackButton = true
    }
    
    deinit {
        listener?.remove()
    }
    
    private func startListeningForPosts() {
        let db = Firestore.firestore()
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.posts = documents.compactMap { doc -> Post? in
                    let data = doc.data()
                    let docId = doc.documentID
                    
                    let username = data["username"] as? String ?? "مستخدم"
                    let userImage = data["userImage"] as? String ?? "person.circle.fill"
                    let postImage = data["postImage"] as? String ?? ""
                    let caption = data["caption"] as? String ?? ""
                    let likesCountInt = data["likesCount"] as? Int ?? 0
                    
                    let likedBy = data["likedBy"] as? [String] ?? []
                    let isLiked = likedBy.contains(currentUID)
                    
                    let timestamp = data["timestamp"] as? Timestamp
                    let date = timestamp?.dateValue() ?? Date()
                    
                    let formatter = RelativeDateTimeFormatter()
                    formatter.unitsStyle = .full
                    let timeAgoString = formatter.localizedString(for: date, relativeTo: Date())
                    
                    return Post(
                        id: docId,
                        username: username,
                        userImage: userImage,
                        postImage: postImage,
                        likesCount: "\(likesCountInt)",
                        caption: caption,
                        timeAgo: timeAgoString,
                        isLiked: isLiked
                    )
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    func toggleLike(for post: Post) {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(post.id)
        
        if post.isLiked {
            postRef.updateData([
                "likedBy": FieldValue.arrayRemove([currentUID]),
                "likesCount": FieldValue.increment(Int64(-1))
            ])
        } else {
            postRef.updateData([
                "likedBy": FieldValue.arrayUnion([currentUID]),
                "likesCount": FieldValue.increment(Int64(1))
            ])
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostTableViewCell else {
            return UITableViewCell()
        }
        
        let post = posts[indexPath.row]
        cell.configure(with: post)
        
        cell.likeAction = { [weak self] in
            self?.toggleLike(for: post)
        }
        
        cell.commentAction = { [weak self] in
            self?.performSegue(withIdentifier: "goToComments", sender: post)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToComments" {
            if let commentsVC = segue.destination as? CommentsViewController,
               let selectedPost = sender as? Post {
                commentsVC.postID = selectedPost.id
            }
        }
    }
}

class PostTableViewCell: UITableViewCell {
    @IBOutlet weak var userProfileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UIButton!
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!
    
    @IBOutlet weak var likesCountLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentButton: UIButton!
    
    var likeAction: (() -> Void)?
    var commentAction: (() -> Void)?
    
    private var profileDataTask: URLSessionDataTask?
    private var postDataTask: URLSessionDataTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userProfileImageView.layer.cornerRadius = userProfileImageView.frame.height / 2
        userProfileImageView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileDataTask?.cancel()
        postDataTask?.cancel()
        userProfileImageView.image = UIImage(systemName: "person.circle.fill")
        postImageView.image = UIImage(systemName: "photo.fill")
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = .black
    }

    @IBAction func likeButtonTapped(_ sender: UIButton) {
        likeAction?()
        
        let isCurrentlyLiked = likeButton.imageView?.image == UIImage(systemName: "heart.fill")
        let newImage = isCurrentlyLiked ? "heart" : "heart.fill"
        let newColor = isCurrentlyLiked ? UIColor.black : UIColor.systemRed
        
        UIView.transition(with: likeButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.likeButton.setImage(UIImage(systemName: newImage), for: .normal)
            self.likeButton.tintColor = newColor
        })
    }
    
    @IBAction func commentButtonTapped(_ sender: UIButton) {
        commentAction?()
    }
    
    func configure(with post: Post) {
        usernameLabel.setTitle(post.username, for: .normal)
        captionLabel.text = "\(post.username) \(post.caption)"
        timeAgoLabel.text = post.timeAgo
        likesCountLabel.text = "\(post.likesCount) likes"
        
        let heartIcon = post.isLiked ? "heart.fill" : "heart"
        let heartColor = post.isLiked ? UIColor.systemRed : UIColor.black
        likeButton.setImage(UIImage(systemName: heartIcon), for: .normal)
        likeButton.tintColor = heartColor
        
        if post.userImage.hasPrefix("http"), let userImgUrl = URL(string: post.userImage) {
            profileDataTask = URLSession.shared.dataTask(with: userImgUrl) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.userProfileImageView.image = image
                    }
                }
            }
            profileDataTask?.resume()
        } else {
            userProfileImageView.image = UIImage(systemName: post.userImage.isEmpty || post.userImage == "person.circle.fill" ? "person.circle.fill" : post.userImage)
        }
        
        if let url = URL(string: post.postImage) {
            postDataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.postImageView.image = image
                    }
                }
            }
            postDataTask?.resume()
        } else {
            postImageView.image = UIImage(systemName: "photo.fill")
        }
    }
}
