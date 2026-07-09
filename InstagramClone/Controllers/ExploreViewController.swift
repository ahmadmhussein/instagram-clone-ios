//
//   ExploreViewController.swift
//   InstagramClone
//
//   Created by Ahmad on 28/06/2026.
//
import UIKit
import FirebaseFirestore
import FirebaseAuth

class ExploreViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    var usersList: [[String: Any]] = []
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        fetchAllUsers()
        
    }
    
    private func fetchAllUsers() {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self.usersList = documents.compactMap { doc -> [String: Any]? in
                if doc.documentID == currentUID { return nil } // تجاهل حساب المستخدم الحالي
                var data = doc.data()
                data["uid"] = doc.documentID
                return data
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as? UserSearchTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: usersList[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            fetchAllUsers()
            return
        }
        
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users")
            .whereField("name", isGreaterThanOrEqualTo: searchText)
            .whereField("name", isLessThanOrEqualTo: searchText + "\u{f8ff}")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.usersList = documents.compactMap { doc -> [String: Any]? in
                    if doc.documentID == currentUID { return nil } // تجاهل حساب المستخدم الحالي في نتائج البحث
                    var data = doc.data()
                    data["uid"] = doc.documentID
                    return data
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUserData = usersList[indexPath.row]
        performSegue(withIdentifier: "showOtherProfile", sender: selectedUserData)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOtherProfile" {
            if let profileVC = segue.destination as? OtherUserProfileViewController,
               let userData = sender as? [String: Any],
               let uid = userData["uid"] as? String,
               let name = userData["name"] as? String {
                
                let selectedUser = ChatUser(uid: uid, name: name)
                profileVC.user = selectedUser
            }
        }
    }
}

class UserSearchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    
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
    
    func configure(with userData: [String: Any]) {
        let name = userData["name"] as? String ?? "مستخدم"
        let bio = userData["bio"] as? String ?? ""
        let profileImageUrlString = userData["profileImageUrl"] as? String ?? ""
        
        nameLabel.text = name
        bioLabel.text = bio
        
        if !profileImageUrlString.isEmpty, let url = URL(string: profileImageUrlString) {
            dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.userImageView.image = image
                    }
                }
            }
            dataTask?.resume()
        } else {
            userImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
}
