import UIKit
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

class AddPostViewController: UIViewController, PHPickerViewControllerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionTextView: UITextView!
    @IBOutlet weak var ContentView: UIView!
    
    private let placeholderText = "write caption....."
    
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
        self.navigationItem.hidesBackButton = true

        // إخفاء زر الرجوع من الـ Tab Bar اللي بيحتوي هاي الشاشة (هذا هو السر!)
        self.tabBarController?.navigationItem.hidesBackButton = true
    }
    
    private func setupUI() {
        captionTextView.delegate = self
        captionTextView.layer.borderWidth = 0.5
        captionTextView.layer.borderColor = UIColor.lightGray.cgColor
        captionTextView.layer.cornerRadius = 8
        
        captionTextView.text = placeholderText
        captionTextView.textColor = .lightGray
        
        postImageView.image = UIImage(systemName: "photo.fill")
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
        postImageView.isUserInteractionEnabled = true
        postImageView.addGestureRecognizer(tapGesture)
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
                    self?.postImageView.image = selectedImage
                }
            }
        }
    }
    
    func textViewDidBeginEditing(_ UITextView: UITextView) {
        if captionTextView.textColor == .lightGray {
            captionTextView.text = nil
            captionTextView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ UITextView: UITextView) {
        if captionTextView.text.isEmpty {
            captionTextView.text = placeholderText
            captionTextView.textColor = .lightGray
        }
    }
    
    private func clearFields() {
        postImageView.image = UIImage(systemName: "photo.fill")
        captionTextView.text = placeholderText
        captionTextView.textColor = .lightGray
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(title: "نجاح", message: "تم حفظ المنشور بنجاح!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "موافق", style: .default, handler: { _ in
            self.dismiss(animated: true)
        }))
        present(alert, animated: true)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let image = postImageView.image,
              image != UIImage(systemName: "photo.fill"),
              let imageData = image.jpegData(compressionQuality: 0.5),
              let userID = Auth.auth().currentUser?.uid else {
            return
        }
        
        sender.isEnabled = false
        activityIndicator.startAnimating()
        
        var caption = captionTextView.text ?? ""
        if caption == placeholderText && captionTextView.textColor == .lightGray {
            caption = ""
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            let currentUserEmail = Auth.auth().currentUser?.email ?? "مستخدم_إنستغرام"
            let defaultName = Auth.auth().currentUser?.displayName ?? currentUserEmail.components(separatedBy: "@").first ?? "مستخدم_إنستغرام"
            
            var finalUsername = defaultName
            var finalUserImage = "person.circle.fill"
            
            if let document = document, document.exists, let data = document.data() {
                finalUsername = data["name"] as? String ?? defaultName
                finalUserImage = data["profileImageUrl"] as? String ?? "person.circle.fill"
            }
            
            let postID = UUID().uuidString
            let storageRef = Storage.storage().reference().child("posts_images/\(postID).jpg")
            
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        sender.isEnabled = true
                        self.activityIndicator.stopAnimating()
                    }
                    return
                }
                
                storageRef.downloadURL { url, error in
                    guard let imageUrlString = url?.absoluteString else {
                        DispatchQueue.main.async {
                            sender.isEnabled = true
                            self.activityIndicator.stopAnimating()
                        }
                        return
                    }
                    
                    let postData: [String: Any] = [
                        "username": finalUsername,
                        "userImage": finalUserImage,
                        "postImage": imageUrlString,
                        "caption": caption,
                        "likesCount": 0,
                        "timestamp": FieldValue.serverTimestamp()
                    ]
                    
                    db.collection("posts").document(postID).setData(postData) { error in
                        DispatchQueue.main.async {
                            sender.isEnabled = true
                            self.activityIndicator.stopAnimating()
                            
                            if let error = error {
                                print(error.localizedDescription)
                            } else {
                                self.clearFields()
                                self.showSuccessAlert()
                            }
                        }
                    }
                }
            }
        }
    }
}
