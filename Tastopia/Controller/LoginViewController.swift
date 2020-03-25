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
    @IBOutlet weak var appleButtonView: UIView!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var eulaButton: UIButton!
    
    fileprivate var currentNonce: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        setBeginLayout()
        
        setAppleButton()

    }
    
    @IBAction func googleSignIn(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func facebookLogin(_ sender: UIButton) {
        
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
                
                TTSwiftMessages().wait(title: "登入中")
                UserProvider.shared.login(credential: credential, name: nil, email: nil) { [weak self] (isLogin) in
                    if isLogin {
                        self?.showHomeVC()
                    } else {
                        TTSwiftMessages().hide()
                        TTSwiftMessages().show(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "登入失敗", body: "")
                    }
                }
            }
        }
        
    }
    
    @IBAction func showPrivacyPolicy(_ sender: UIButton) {
        if let url = URL(string: "https://bacteriafish.github.io") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func showEULA(_ sender: UIButton) {
        if let url = URL(string: "https://www.eulatemplate.com/live.php?token=EeoBzLEiaDGeNQo59O8FrAV2alEGII6t") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func setBeginLayout() {
        
        googleButton.layer.cornerRadius = 24
        facebookButton.layer.cornerRadius = 24
        
        setButtonTitleUnderline(button: privacyButton, title: "隱私權政策")
        setButtonTitleUnderline(button: eulaButton, title: "使用條款")

    }
    
    private func setButtonTitleUnderline(button: UIButton, title: String) {
        
        let attribute: [NSAttributedString.Key: Any] = [
            .font: UIFont(name: "NotoSansTC-Bold", size: 16)!,
            .foregroundColor: UIColor.SUMI!,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        let attributeString = NSMutableAttributedString(string: title, attributes: attribute)
        button.setAttributedTitle(attributeString, for: .normal)
    }
    
    private func setAppleButton() {
        
        if #available(iOS 13, *) {
            appleButtonView.isHidden = false
            let button = ASAuthorizationAppleIDButton(type: .default, style: .black)
            button.frame = CGRect(x: 0, y: 0, width: appleButtonView.frame.width, height: appleButtonView.frame.height)
            button.cornerRadius = 24
            button.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
            appleButtonView.addSubview(button)
        }
    }
    
    private func showHomeVC() {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let homeStoryboard = UIStoryboard(name: TTConstant.StoryboardName.home, bundle: nil)
        
        guard let homeVC = homeStoryboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController else { return }
        
        appDelegate.window?.rootViewController = homeVC
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

extension LoginViewController: GIDSignInDelegate {
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.hasNoAuthInKeychain.rawValue {
                print("The user has not signed in before or they have since signed out.")
            } else {
                print("\(error.localizedDescription)")
            }
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
    
        TTSwiftMessages().wait(title: "登入中")
        UserProvider.shared.login(credential: credential, name: nil, email: nil) { [weak self] (isLogin) in
            if isLogin {
                self?.showHomeVC()
            } else {
                TTSwiftMessages().hide()
                TTSwiftMessages().show(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "登入失敗", body: "")
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
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
            let email = appleIDCredential.email

            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)

            TTSwiftMessages().wait(title: "登入中")
            UserProvider.shared.login(credential: credential, name: name, email: email) { [weak self] (isLogin) in
                if isLogin {
                    self?.showHomeVC()
                } else {
                    TTSwiftMessages().hide()
                    TTSwiftMessages().show(color: UIColor.AKABENI!, icon: UIImage.asset(.Icon_32px_Error_White)!, title: "登入失敗", body: "")
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        TTSwiftMessages().hide()
        
        print("Sign in with Apple errored: \(error)")
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}
