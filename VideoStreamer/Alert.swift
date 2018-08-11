//
//  Alert.swift
//  VideoStreamer
//
//  Created by SARMAH, RITAM on 8/9/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import UIKit

struct Alert {
    
    private init() {}
    
    private static let okAction = UIAlertAction(title: "OK", style: .default)
    
    private static func presentAlert(on viewController: UIViewController, title: String?, message: String?, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        viewController.present(alert, animated: true)
    }
    
    static func presentPlaybackError(on viewController: UIViewController) {
        presentAlert(on: viewController, title: "An error occurred loading this video", message: nil, actions: [
            UIAlertAction(title: "Close", style: .default, handler: { _ in
                viewController.dismiss(animated: true)
            })
        ])
    }
    
    // MARK: Downloading
    
    static func presentDownloadSuccess(on viewController: UIViewController, for video: Video) {
        let message = "\"\(video.title)\" is now available offline"
        presentAlert(on: viewController, title: "Download successful!", message: message, actions: [okAction])
    }
    
    static func presentDownloadExists(on viewController: UIViewController) {
        presentAlert(on: viewController, title: "Video already downloaded!", message: nil, actions: [okAction])
    }
}
