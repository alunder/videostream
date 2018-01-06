//
//  CopyableLabel.swift
//
//  Created by Ritam Sarmah on 1/4/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import UIKit

class CopyableLabel: UILabel {
    
    override var canBecomeFirstResponder: Bool { return true }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }
    
    func sharedInit() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(
            target: self,
            action: #selector(showMenu(sender:))
        ))
        addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(hideMenu(sender:))
        ))
    }
    
    override func copy(_ sender: Any?) {
        if let text = text {
            let breakIndex = text.index(after: text.index(of: "\n")!)
            let copyableText = text[breakIndex..<text.endIndex]
            UIPasteboard.general.string = String(copyableText)
        }
        UIMenuController.shared.setMenuVisible(false, animated: true)
    }
    
    @objc func showMenu(sender: Any?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    @objc func hideMenu(sender: Any?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(false, animated: true)
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }
}
