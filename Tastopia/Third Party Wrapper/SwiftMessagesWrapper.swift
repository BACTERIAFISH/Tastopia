//
//  SwiftMessagesWrapper.swift
//  Tastopia
//
//  Created by FISH on 2020/2/22.
//  Copyright © 2020 FISH. All rights reserved.
//

import UIKit
import SwiftMessages

class TTSwiftMessages {
    
    func hideAll() {
        SwiftMessages.hideAll()
    }
    
    func hide() {
        SwiftMessages.hide()
    }
    
    func wait(title: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(backgroundColor: UIColor.SUMI!, foregroundColor: .white)
        view.configureContent(title: title, body: "請稍等", iconImage: UIImage.asset(.Icon_32px_Time_White)!)
        view.titleLabel?.font = UIFont(name: "NotoSansTC-Bold", size: 20)
        view.bodyLabel?.font = UIFont(name: "NotoSansTC-Regular", size: 18)
        view.button?.isHidden = true
        view.configureDropShadow()
        view.layoutMarginAdditions = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 16
        
        var config = SwiftMessages.Config()
        
        config.duration = .forever
        config.dimMode = .gray(interactive: false)
        config.interactiveHide = false
        config.presentationContext = .window(windowLevel: .normal)
        
        SwiftMessages.show(config: config, view: view)
    }
    
    func show(color: UIColor, icon: UIImage, title: String, body: String, duration: TimeInterval? = 1.5) {
        
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(backgroundColor: color, foregroundColor: .white)
        view.configureContent(title: title, body: body, iconImage: icon)
        view.titleLabel?.font = UIFont(name: "NotoSansTC-Bold", size: 20)
        view.bodyLabel?.font = UIFont(name: "NotoSansTC-Regular", size: 18)
        view.button?.isHidden = true
        view.configureDropShadow()
        view.layoutMarginAdditions = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 16
        
        var config = SwiftMessages.Config()
        
        config.presentationContext = .window(windowLevel: .normal)
        
        if let duration = duration {
            config.duration = .seconds(seconds: duration)
        } else {
            config.duration = .forever
        }
        
        SwiftMessages.show(config: config, view: view)
    }
    
    func pause(color: UIColor, icon: UIImage, title: String, body: String, handler: (() -> Void)?) {
        
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(backgroundColor: color, foregroundColor: .white)
        view.configureContent(title: title, body: body, iconImage: icon)
        view.titleLabel?.font = UIFont(name: "NotoSansTC-Bold", size: 20)
        view.bodyLabel?.font = UIFont(name: "NotoSansTC-Regular", size: 18)
        view.button?.isHidden = true
        view.configureDropShadow()
        view.layoutMarginAdditions = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 16
        
        var config = SwiftMessages.Config()
        
        config.dimMode = .gray(interactive: true)
        config.duration = .forever
        
        config.eventListeners.append { (event) in
            if event == .didHide {
                handler?()
            }
        }
        
        SwiftMessages.show(config: config, view: view)
    }
    
    func question(title: String?, body: String?, leftButtonTitle: String?, rightButtonTitle: String?, rightHandler: (() -> Void)?) {
        
        do {
            let view: QuestionView = try SwiftMessages.viewFromNib()
            
            view.contentView.layer.cornerRadius = 16
            view.contentView.layer.createTTShadow(color: UIColor.black.cgColor, offset: CGSize(width: 0, height: 2), radius: 6, opacity: 0.4)
            view.leftButton.layer.cornerRadius = 16
            view.rightButton.layer.cornerRadius = 16
            
            view.titleLabel.text = title
            view.bodyLabel.text = body
            view.leftButton.setTitle("取消", for: .normal)
            view.rightButton.setTitle(rightButtonTitle, for: .normal)
            
            view.leftHandler = { button in
                SwiftMessages.hide()
//                leftHandler?()
            }
            
            view.rightHandler = { button in
                SwiftMessages.hide()
                rightHandler?()
            }
            
            var config = SwiftMessages.Config()
            
            config.duration = .forever
            config.presentationStyle = .center
            config.dimMode = .gray(interactive: true)
            
            SwiftMessages.show(config: config, view: view)
            
        } catch {
            print("TTSwiftMessages question error")
        }
    }
    
    func info(title: String?, body: String?, icon: UIImage?, buttonTitle: String?, backgroundColor: UIColor = .white, foregroundColor: UIColor = UIColor.SUMI!, isStatusBarLight: Bool = true, handler: (() -> Void)?) {
        
        let view = MessageView.viewFromNib(layout: .centeredView)
        view.configureContent(title: title, body: body, iconImage: icon, iconText: nil, buttonImage: nil, buttonTitle: buttonTitle, buttonTapHandler: { _ in
            SwiftMessages.hide()
            handler?()
        })
        view.configureTheme(backgroundColor: backgroundColor, foregroundColor: foregroundColor)
        view.titleLabel?.font = UIFont(name: "NotoSansTC-Bold", size: 20)
        view.bodyLabel?.font = UIFont(name: "NotoSansTC-Regular", size: 18)
        view.bodyLabel?.textAlignment = .left
        view.button?.titleLabel?.font = UIFont(name: "NotoSansTC-Bold", size: 20)
        view.button?.layer.cornerRadius = 16
        view.button?.contentEdgeInsets = UIEdgeInsets(top: 9, left: 50, bottom: 9, right: 50)
        
        view.configureDropShadow()
        view.layoutMarginAdditions = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 16
        
        var config = SwiftMessages.Config()
        
        config.presentationStyle = .center
        config.dimMode = .color(color: .clear, interactive: false)
        config.duration = .forever
        config.interactiveHide = false
        
        if isStatusBarLight {
            config.preferredStatusBarStyle = .lightContent
        }
        
        SwiftMessages.show(config: config, view: view)
    }
}
