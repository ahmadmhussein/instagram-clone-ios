import UIKit
import FirebaseFirestore
import FirebaseAuth


class DirectMessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var users: [ChatUser] = []
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        fetchUsers()
        
    }
    
    func fetchUsers() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self?.users.removeAll()
            for document in documents {
                let data = document.data()
                let uid = document.documentID
                let name = data["name"] as? String ?? "مستخدم"
                
                if uid != currentUID {
                    self?.users.append(ChatUser(uid: uid, name: name))
                }
            }
            
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InboxCell", for: indexPath) as! InboxTableViewCell
        let user = users[indexPath.row]
        
        cell.userNameLabel.text = user.name
        cell.lastMessageLabel.text = "اضغط لبدء المحادثة..."
        cell.userImageView.image = UIImage(systemName: "person.circle.fill")
        cell.userImageView.tintColor = .gray
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = users[indexPath.row]
        performSegue(withIdentifier: "goToChat", sender: selectedUser)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChat" {
            if let chatVC = segue.destination as? ChatRoomViewController,
               let selectedUser = sender as? ChatUser {
                chatVC.title = selectedUser.name
                chatVC.receiverID = selectedUser.uid
            }
        }
    }
}

class InboxTableViewCell: UITableViewCell {
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.clipsToBounds = true
    }
}
