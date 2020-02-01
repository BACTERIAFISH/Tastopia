//
//  ViewController.swift
//  Tastopia
//
//  Created by FISH on 2020/1/30.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FacebookLogin
import AuthenticationServices
import CryptoKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var googleButton: UIButton!
    @IBOutlet weak var facebookButton: UIButton!
//    @IBOutlet weak var appleView: UIView!
    @IBOutlet weak var appleButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        googleButton.layer.cornerRadius = 5
        facebookButton.layer.cornerRadius = 5
        appleButton.layer.cornerRadius = 5
        
        if #available(iOS 13, *) {
//            appleView.isHidden = false
//            let button = ASAuthorizationAppleIDButton(type: .default, style: .white)
//            button.frame = CGRect(x: 0, y: 0, width: appleView.frame.width, height: appleView.frame.height)
//            button.cornerRadius = 5
//            button.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
//            appleView.addSubview(button)
            
            appleButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
        }
        
    }
    
    @IBAction func googleSignInPress(_ sender: Any) {
        googleSignIn()
    }
    
    func googleSignIn() {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func fbLogin(_ sender: Any) {
        facebookLogin()
    }
    
    func facebookLogin() {
        let loginManager = LoginManager()
        loginManager.logIn(
            permissions: [.publicProfile, .email],
            viewController: self
        ) { result in
            switch result {
            case .cancelled:
                print("fb login cancelled")
            case .failed(let error):
                print("fb login fail: \(error)")
            case .success(_, _, let accessToken):
                print("fb login success")
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if let error = error {
                        print("firebase fb login error: \(error)")
                        return
                    }
                    print("firebase fb login")
                    if let user = authResult?.user, let refreshToken = user.refreshToken {
                        
                        if let name = user.displayName, let email = user.email {
                            let userdata = UserData(uid: user.uid, name: name, email: email)
                            FirestoreManager.shared.addData(collection: "Users", document: user.uid, data: userdata)
                        }
                        
                        UserDefaults.standard.set(refreshToken, forKey: "firebaseToken")
                    }
                    
                    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    guard let tabBarVC = mainStoryboard.instantiateViewController(identifier: "MainTabBarController") as? UITabBarController else { return }
                    appDelegate.window?.rootViewController = tabBarVC
                    appDelegate.window?.makeKeyAndVisible()
                }
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if length == 0 { return }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    // Unhashed nonce.
    fileprivate var currentNonce: String?
    
    @available(iOS 13, *)
    @objc func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

@available(iOS 13.0, *)
extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let familyName = appleIDCredential.fullName?.familyName ?? ""
            let givenName = appleIDCredential.fullName?.givenName ?? ""
            let name = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
            var email = appleIDCredential.email

            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error.localizedDescription)
                    return
                }
                print("firebase apple sign in")
                if let user = authResult?.user, let refreshToken = user.refreshToken {
                    
                    if email == nil {
                        email = user.email
                    }
                    if let email = email {
                        let userdata = UserData(uid: user.uid, name: name, email: email)
                        FirestoreManager.shared.addData(collection: "Users", document: user.uid, data: userdata)
                    }
                    
                    UserDefaults.standard.set(refreshToken, forKey: "firebaseToken")
                }
                guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
                let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                guard let tabBarVC = mainStoryboard.instantiateViewController(identifier: "MainTabBarController") as? UITabBarController else { return }
                appDelegate.window?.rootViewController = tabBarVC
                appDelegate.window?.makeKeyAndVisible()
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        print("Sign in with Apple errored: \(error)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
