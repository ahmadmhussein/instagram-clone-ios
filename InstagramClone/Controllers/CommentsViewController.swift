//
//  CommentsViewController.swift
//  InstagramClone
//
//  Created by Ahmad on 05/07/2026.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

struct Comment {
    let username: String
    let userImage: String
    let text: String
    let timestamp: Double
}

class CommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    var postID: String?
    var comments: [Comment] = []
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.title = "Comments"
        tableView.rowHeight = 85
        
        
        fetchComments()
    }
    
    func fetchComments() {
        guard let postID = postID else { return }
        
        db.collection("posts").document(postID).collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.comments = documents.compactMap { doc -> Comment? in
                    let data = doc.data()
                    let username = data["username"] as? String ?? "مستخدم"
                    let userImage = data["userImage"] as? String ?? ""
                    let text = data["text"] as? String ?? ""
                    let timestamp = data["timestamp"] as? Double ?? 0.0
                    
                    return Comment(username: username, userImage: userImage, text: text, timestamp: timestamp)
                }
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                    if let count = self?.comments.count, count > 0 {
                        let indexPath = IndexPath(row: count - 1, section: 0)
                        self?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
            }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentTableViewCell
        let comment = comments[indexPath.row]
        cell.configure(with: comment)
        return cell
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let text = commentTextField.text, !text.isEmpty,
              let postID = postID,
              let currentUID = Auth.auth().currentUser?.uid else { return }
        
        commentTextField.text = ""
        db.collection("users").document(currentUID).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let username = data["name"] as? String else { return }
            
            let userImage = data["profileImageUrl"] as? String ?? ""
            
            let commentData: [String: Any] = [
                "username": username,
                "userImage": userImage,
                "text": text,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            self?.db.collection("posts").document(postID).collection("comments").addDocument(data: commentData)
        }
    }
}

class CommentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    private var dataTask: URLSessionDataTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dataTask?.cancel()
        userImageView.image = UIImage(systemName: "person.circle.fill")
    }
    
    func configure(with comment: Comment) {
        usernameLabel.text = comment.username
        commentLabel.text = comment.text
        
        if let url = URL(string: comment.userImage), !comment.userImage.isEmpty {
            dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.userImageView.image = image
                    }
                }
            }
            dataTask?.resume()
        }
    }
}
