//
//  sidemenuViewController.swift
//  InstagramClone
//
//  Created by Ahmad on 29/06/2026.
//

import UIKit
import FirebaseAuth
class sidemenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func logoutTapped(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
                        
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        
                        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC")
                        
                        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                              let window = windowScene.windows.first else { return }
                        
                        window.rootViewController = loginVC
                        window.makeKeyAndVisible()
                        
                        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                        
                    } catch let signOutError {
                        print("خطأ أثناء تسجيل الخروج: \(signOutError.localizedDescription)")
                    }
                }
    }
    

