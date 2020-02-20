//
//  JGProgressHUDWrapper.swift
//  Tastopia
//
//  Created by FISH on 2020/2/16.
//  Copyright © 2020 FISH. All rights reserved.
//

import JGProgressHUD

class TTProgressHUD {
    
    static let shared = TTProgressHUD()
    
    let hud = JGProgressHUD(style: .dark)
    
    private init() {}
    
    func showLoading(in view: UIView, text: String = "Loading") {

        if !Thread.isMainThread {

            DispatchQueue.main.async { [weak self] in
                self?.showLoading(in: view, text: text)
            }

            return
        }

        hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()

        hud.textLabel.text = text

        hud.show(in: view)
        
    }
    
    func showFail(in view: UIView, text: String = "Fail") {

        if !Thread.isMainThread {

            DispatchQueue.main.async { [weak self] in
                self?.showFail(in: view, text: text)
            }

            return
        }
        
        let hud = JGProgressHUD(style: .dark)

        hud.indicatorView = JGProgressHUDErrorIndicatorView()

        hud.textLabel.text = text

        hud.show(in: view)
        
        hud.dismiss(afterDelay: 1)
    }
    
    func showSuccess(in view: UIView, text: String = "Success") {

        if !Thread.isMainThread {

            DispatchQueue.main.async { [weak self] in
                self?.showSuccess(in: view, text: text)
            }

            return
        }
        
        let hud = JGProgressHUD(style: .dark)

        hud.indicatorView = JGProgressHUDSuccessIndicatorView()

        hud.textLabel.text = text

        hud.show(in: view)
        
        hud.dismiss(afterDelay: 1)
    }
}
