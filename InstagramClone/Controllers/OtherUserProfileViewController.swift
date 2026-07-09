//
//  OtherUserProfileViewController.swift
//  InstagramClone
//
//  Created by Ahmad on 30/06/2026.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class OtherUserProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var postsCountLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var user: ChatUser?
    var userPosts: [String] = []
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.clipsToBounds = true
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupUserData()
        fetchUserDataAndPosts()
    }
    
    func setupUserData() {
        guard let user = user else { return }
        nameLabel.text = user.name
        bioLabel.text = ""
        postsCountLabel.text = "0"
    }
    
    private func fetchUserDataAndPosts() {
        guard let user = user else { return }
        
        db.collection("users").document(user.uid).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let document = document, document.exists, let data = document.data() {
                if let bio = data["bio"] as? String {
                    self.bioLabel.text = bio
                }
                
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
            }
        }
        
        db.collection("posts")
            .whereField("username", isEqualTo: user.name)
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
    
    @IBAction func followButtonTapped(_ sender: UIButton) {
        followButton.setTitle("Unfollow", for: .normal)
    }
    
    @IBAction func messageButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToChatFromProfile", sender: user)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToChatFromProfile" {
            if let chatVC = segue.destination as? ChatRoomViewController,
               let selectedUser = sender as? ChatUser {
                chatVC.title = selectedUser.name
                chatVC.receiverID = selectedUser.uid
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OtherUserPostCell", for: indexPath) as! OtherUserPostCell
        if !userPosts.isEmpty {
            cell.configure(with: userPosts[indexPath.item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = (collectionView.frame.width - 4) / 3
        return CGSize(width: size, height: size)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
}

class OtherUserPostCell: UICollectionViewCell {
    
    @IBOutlet weak var postImageView: UIImageView!
    
    func configure(with urlString: String) {
        postImageView.contentMode = .scaleAspectFill
        postImageView.clipsToBounds = true
        
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.postImageView.image = image
                    }
                }
            }
            .resume()
        } else {
            postImageView.image = UIImage(systemName: "photo")
        }
    }
}
