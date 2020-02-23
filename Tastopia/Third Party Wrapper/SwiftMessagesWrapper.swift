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
        
//        config.presentationStyle = .top
        config.duration = .forever
        config.dimMode = .gray(interactive: false)
        config.interactiveHide = false
        
        SwiftMessages.show(config: config, view: view)
    }
    
    func checkTaskError(body: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(backgroundColor: UIColor.AKABENI!, foregroundColor: .white)
        view.configureContent(title: "上傳失敗", body: body, iconImage: UIImage.asset(.Icon_32px_Error_White)!)
        view.titleLabel?.font = UIFont(name: "NotoSansTC-Bold", size: 20)
        view.bodyLabel?.font = UIFont(name: "NotoSansTC-Regular", size: 18)
        view.button?.isHidden = true
        view.configureDropShadow()
        view.layoutMarginAdditions = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 16
        
        var config = SwiftMessages.Config()
        
        config.duration = .seconds(seconds: 1.5)
        
        SwiftMessages.show(config: config, view: view)
    }
    
    func success(title: String, body: String) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(backgroundColor: UIColor.SUMI!, foregroundColor: .white)
        view.configureContent(title: title, body: body, iconImage: UIImage.asset(.Icon_32px_Success_White)!)
        view.titleLabel?.font = UIFont(name: "NotoSansTC-Bold", size: 20)
        view.bodyLabel?.font = UIFont(name: "NotoSansTC-Regular", size: 18)
        view.button?.isHidden = true
        view.configureDropShadow()
        view.layoutMarginAdditions = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 16
        
        var config = SwiftMessages.Config()
        
        config.duration = .seconds(seconds: 1.5)
        
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
    
    func question(title: String?, body: String?, leftButtonTitle: String?, rightButtonTitle: String?, leftHandler: (() -> Void)?, rightHandler: (() -> Void)?) {
        
        do {
            let view: QuestionView = try SwiftMessages.viewFromNib()
            
            view.contentView.layer.cornerRadius = 16
            view.contentView.layer.createTTShadow(color: UIColor.black.cgColor, offset: CGSize(width: 0, height: 2), radius: 6, opacity: 0.4)
            view.leftButton.layer.cornerRadius = 16
            view.rightButton.layer.cornerRadius = 16
            
            view.titleLabel.text = title
            view.bodyLabel.text = body
            view.leftButton.setTitle(leftButtonTitle, for: .normal)
            view.rightButton.setTitle(rightButtonTitle, for: .normal)
            
            view.leftHandler = { button in
                SwiftMessages.hide()
                leftHandler?()
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
            
        }
        
    }
}
