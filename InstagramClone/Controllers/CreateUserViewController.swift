//
//  CreateUserViewController.swift
//  InstagramClone
//
//  Created by Ahmad on 24/06/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class CreateUserViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var PassWordTextField: UITextField!
    @IBOutlet weak var NameTextField: UITextField!
    @IBOutlet weak var passWord2TextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupEmailTextFieldIcon()
        setupNameTextFieldIcon()
        setupPasswordTextFieldIcon()
        setupConfirmPasswordTextFieldIcon()
    }
    
    private func setupEmailTextFieldIcon() {
        let iconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let iconImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        
        iconImageView.image = UIImage(systemName: "envelope")
        iconImageView.tintColor = .systemGray
        iconImageView.contentMode = .scaleAspectFit
        
        iconContainerView.addSubview(iconImageView)
        emailTextField.rightView = iconContainerView
        emailTextField.rightViewMode = .always
        emailTextField.textAlignment = .right
    }
    
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        sender.isSelected.toggle()
        PassWordTextField.isSecureTextEntry.toggle()
        passWord2TextField.isSecureTextEntry.toggle()
    }
    
    private func setupNameTextFieldIcon() {
        let iconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let iconImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        
        iconImageView.image = UIImage(systemName: "person")
        iconImageView.tintColor = .systemGray
        iconImageView.contentMode = .scaleAspectFit
        
        iconContainerView.addSubview(iconImageView)
        NameTextField.rightView = iconContainerView
        NameTextField.rightViewMode = .always
        NameTextField.textAlignment = .right
    }
    
    private func setupPasswordTextFieldIcon() {
        let rightContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let lockImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        
        lockImageView.image = UIImage(systemName: "lock")
        lockImageView.tintColor = .systemGray
        lockImageView.contentMode = .scaleAspectFit
        rightContainerView.addSubview(lockImageView)
        
        PassWordTextField.rightView = rightContainerView
        PassWordTextField.rightViewMode = .always
        
        let leftContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 45, height: 40))
        let eyeButton = UIButton(type: .custom)
        eyeButton.frame = CGRect(x: 10, y: 10, width: 25, height: 20)
        eyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
        eyeButton.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        eyeButton.tintColor = .systemGray
        
        eyeButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        leftContainerView.addSubview(eyeButton)
        
        PassWordTextField.leftView = leftContainerView
        PassWordTextField.leftViewMode = .always
        PassWordTextField.textAlignment = .right
    }
    
    private func setupConfirmPasswordTextFieldIcon() {
        let iconContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        let iconImageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 20, height: 20))
        
        iconImageView.image = UIImage(systemName: "checkmark.shield")
        iconImageView.tintColor = .systemGray
        iconImageView.contentMode = .scaleAspectFit
        
        iconContainerView.addSubview(iconImageView)
        passWord2TextField.rightView = iconContainerView
        passWord2TextField.rightViewMode = .always
        passWord2TextField.textAlignment = .right
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "موافق", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func CreateAccPreesd(_ sender: UIButton) {
            guard let email = emailTextField.text, !email.isEmpty,
                  let password = PassWordTextField.text, !password.isEmpty,
                  let confirmPassword = passWord2TextField.text, !confirmPassword.isEmpty,
                  let name = NameTextField.text, !name.isEmpty else {
                showAlert(title: "خطأ", message: "الرجاء تعبئة جميع الحقول")
                return
            }
            
            guard password == confirmPassword else {
                showAlert(title: "خطأ", message: "كلمات المرور غير متطابقة")
                return
            }
            
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
                if let error = error {
                    self?.showAlert(title: "خطأ في إنشاء الحساب", message: error.localizedDescription)
                    return
                }
                
                guard let uid = authResult?.user.uid else { return }
                
                let userData: [String: Any] = [
                    "uid": uid,
                    "name": name,
                    "email": email
                ]
                
                Firestore.firestore().collection("users").document(uid).setData(userData) { error in
                    if let error = error {
                        self?.showAlert(title: "خطأ في حفظ البيانات", message: error.localizedDescription)
                    } else {
                        self?.showAlert(title: "تم بنجاح", message: "تم إنشاء حسابك بنجاح!")
                    }
                }
            }
        }
    }
