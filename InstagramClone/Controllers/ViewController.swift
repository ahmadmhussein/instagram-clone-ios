//
//  ViewController.swift
//  InstagramClone
//
//  Created by Ahmad on 24/06/2026.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    
    @IBOutlet weak var PassWordTextField: UITextField!
    @IBOutlet weak var EmailTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "موافق", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func LogIn(_ sender: UIButton) {
        guard let email = EmailTextField.text, !email.isEmpty,
              let password = PassWordTextField.text, !password.isEmpty else {
            showAlert(title: "خطأ", message: "الرجاء تعبئة جميع الحقول")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.showAlert(title: "خطأ في تسجيل الدخول", message: error.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                        self?.performSegue(withIdentifier: "goToHome", sender: self)
                    }
        }
    }
}
