import UIKit
import FirebaseFirestore
import FirebaseAuth
import SideMenu // إضافة المكتبة لتتعرف الشاشة على نوع الـ Controller بدون أخطاء

class ProfileViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var postsCountLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var userPosts: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        
        // 💡 التعديل الجديد: إضافة الزر برمجياً لضمان ظهوره في شريط الـ Navigation
        let menuIcon = UIImage(systemName: "line.3.horizontal")
        let menuButton = UIBarButtonItem(image: menuIcon, style: .plain, target: self, action: #selector(menuButtonTapped))
        menuButton.tintColor = .black // يمكنك تغيير اللون إذا كانت خلفيتك داكنة
        self.navigationItem.rightBarButtonItem = menuButton
        
        loadUserDataAndPosts()
    }
    
    // 💡 التعديل الجديد: إضافة @objc لكي يتعرف الكود البرمجي على هذا الأكشن
    @objc @IBAction func menuButtonTapped(_ sender: UIBarButtonItem) {
        guard let menu = storyboard?.instantiateViewController(withIdentifier: "SideMenuID") as? SideMenuNavigationController else {
            print("خطأ: تأكد من وضع الـ Storyboard ID باسم SideMenuID للشاشة الجانبية")
            return
        }
        
        // السر هنا: false تعني ظهور القائمة من اليمين
        menu.leftSide = false
        
        present(menu, animated: true, completion: nil)
    }
    private func loadUserDataAndPosts() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            var currentUserName = ""
            let currentUserEmail = Auth.auth().currentUser?.email ?? "مستخدم"
            let defaultName = Auth.auth().currentUser?.displayName ?? currentUserEmail.components(separatedBy: "@").first ?? "مستخدم"
            
            if let document = document, document.exists, let data = document.data() {
                currentUserName = data["name"] as? String ?? defaultName
                self.descriptionLabel.text = data["bio"] as? String ?? ""
                
                if let profileImageUrlString = data["profileImageUrl"] as? String, let url = URL(string: profileImageUrlString) {
                    URLSession.shared.dataTask(with: url) { data, response, error in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.profileImageView.image = image
                            }
                        }
                    }.resume()
                } else {
                    self.profileImageView.image = UIImage(systemName: "person.circle.fill")
                }
            } else {
                currentUserName = defaultName
                self.descriptionLabel.text = ""
                self.profileImageView.image = UIImage(systemName: "person.circle.fill")
            }
            
            self.usernameLabel.text = currentUserName
            self.fetchUserPosts(with: currentUserName)
        }
    }
    
    private func fetchUserPosts(with username: String) {
        let db = Firestore.firestore()
        
        db.collection("posts")
            .whereField("username", isEqualTo: username)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.userPosts = documents.compactMap { doc -> String? in
                    let data = doc.data()
                    return data["postImage"] as? String
                }
                
                DispatchQueue.main.async {
                    self.postsCountLabel.text = "\(self.userPosts.count)"
                    self.collectionView.reloadData()
                }
            }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCell", for: indexPath) as! ProfileGridCell
        cell.configure(with: userPosts[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 4) / 3
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}

class ProfileGridCell: UICollectionViewCell {
    
    @IBOutlet weak var gridImageView: UIImageView!
    
    func configure(with urlString: String) {
        gridImageView.contentMode = .scaleAspectFill
        gridImageView.clipsToBounds = true
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.gridImageView.image = image
                    }
                }
            }
            .resume()
        } else {
            gridImageView.image = UIImage(systemName: "photo")
        }
    }
}
