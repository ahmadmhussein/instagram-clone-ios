import UIKit
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import PhotosUI

class EditPostViewController: UIViewController, PHPickerViewControllerDelegate {

    @IBOutlet weak var discriptionlabel: UITextView!
    @IBOutlet weak var namelabel: UITextField!
    @IBOutlet weak var profilePic: UIImageView!
    
    private var isImageChanged = false
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .systemBlue
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupImageGesture()
        setupActivityIndicator()
        loadCurrentUserData()
    }
    
    private func setupUI() {
        discriptionlabel.layer.borderWidth = 0.5
        discriptionlabel.layer.borderColor = UIColor.lightGray.cgColor
        discriptionlabel.layer.cornerRadius = 8
        profilePic.layer.cornerRadius = profilePic.frame.height / 2
        profilePic.clipsToBounds = true
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupImageGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImageTapped))
        profilePic.isUserInteractionEnabled = true
        profilePic.addGestureRecognizer(tapGesture)
    }
    
    @objc private func selectImageTapped() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
        
        provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
            if let selectedImage = image as? UIImage {
                DispatchQueue.main.async {
                    self?.profilePic.image = selectedImage
                    self?.isImageChanged = true
                }
            }
        }
    }
    
    private func loadCurrentUserData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { [weak self] document, error in
            guard let self = self, let document = document, document.exists, let data = document.data() else {
                let currentUserEmail = Auth.auth().currentUser?.email ?? ""
                self?.namelabel.text = Auth.auth().currentUser?.displayName ?? currentUserEmail.components(separatedBy: "@").first ?? ""
                return
            }
            
            DispatchQueue.main.async {
                self.namelabel.text = data["name"] as? String ?? ""
                self.discriptionlabel.text = data["bio"] as? String ?? ""
                
                if let profileImageUrlString = data["profileImageUrl"] as? String, let url = URL(string: profileImageUrlString) {
                    URLSession.shared.dataTask(with: url) { data, response, error in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.profilePic.image = image
                            }
                        }
                    }.resume()
                }
            }
        }
    }
    
    private func saveUserData(profileImageUrl: String?) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        var updateData: [String: Any] = [
            "name": namelabel.text ?? "",
            "bio": discriptionlabel.text ?? ""
        ]
        
        if let url = profileImageUrl {
            updateData["profileImageUrl"] = url
        }
        
        db.collection("users").document(userID).setData(updateData, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    let alert = UIAlertController(title: "نجاح", message: "تم تحديث الملف الشخصي بنجاح!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "موافق", style: .default, handler: { _ in
                        self?.dismiss(animated: true)
                    }))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    @IBAction func updateTapped(_ sender: UIButton) {
        activityIndicator.startAnimating()
        
        if isImageChanged, let image = profilePic.image, let imageData = image.jpegData(compressionQuality: 0.5) {
            guard let userID = Auth.auth().currentUser?.uid else { return }
            let storageRef = Storage.storage().reference().child("profile_images/\(userID).jpg")
            
            storageRef.putData(imageData, metadata: nil) { [weak self] metadata, error in
                if let error = error {
                    print(error.localizedDescription)
                    DispatchQueue.main.async { self?.activityIndicator.stopAnimating() }
                    return
                }
                
                storageRef.downloadURL { url, error in
                    guard let imageUrlString = url?.absoluteString else {
                        DispatchQueue.main.async { self?.activityIndicator.stopAnimating() }
                        return
                    }
                    self?.saveUserData(profileImageUrl: imageUrlString)
                }
            }
        } else {
            saveUserData(profileImageUrl: nil)
        }
    }
}
