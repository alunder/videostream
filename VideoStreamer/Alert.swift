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
    private static let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    
    private static func presentAlert(on viewController: UIViewController, title: String?, message: String?, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        viewController.present(alert, animated: true)
    }
    
    private static func presentActionSheet(on viewController: UIViewController, title: String?, message: String?, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
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
        presentAlert(on: viewController, title: "Content already downloaded!", message: nil, actions: [okAction])
    }
    
    static func presentClearDownloads(on viewController: UIViewController) {
        let clearAction = UIAlertAction(title: "Clear Downloaded Content", style: .destructive) { _ in
            VideoInfoManager.shared.deleteAllDownloads()
            if let settingsVC = viewController as? SettingsTableViewController {
                settingsVC.clearDownloadsCell.textLabel!.textColor = .lightGray
                settingsVC.clearDownloadsCell.isUserInteractionEnabled = false
            }
        }
        presentActionSheet(on: viewController,
                           title: "Clearing will remove all downloaded media content. Items will not be removed from your library.",
                           message: nil,
                           actions: [clearAction, cancelAction])
    }
    
    static func presentClearCache(on viewController: UIViewController) {
        let clearAction = UIAlertAction(title: "Clear Cached Data", style: .destructive) { _ in
            VideoInfoManager.shared.resetCache()
            if let settingsVC = viewController as? SettingsTableViewController {
                settingsVC.clearCacheCell.textLabel!.textColor = .lightGray
                settingsVC.clearCacheCell.isUserInteractionEnabled = false
            }
        }
        presentActionSheet(on: viewController,
                           title: "Clearing will remove cached metadata and thumbnails. Items will not be removed from your library.",
                           message: nil,
                           actions: [clearAction, cancelAction])
    }
    
    static func presentPlaybackOptions(on viewController: UIViewController) {
        let startOver = UIAlertAction(title: "Start Over", style: .default) { _ in
            if let infoVC = viewController as? VideoInfoViewController {
                infoVC.video?.lastPlayedTime = nil
                infoVC.performSegue(withIdentifier: Storyboard.PlayerFromInfoSegue, sender: viewController)
            }
        }
        let resume = UIAlertAction(title: "Resume", style: .default) { _ in
            if let infoVC = viewController as? VideoInfoViewController {
                infoVC.performSegue(withIdentifier: Storyboard.PlayerFromInfoSegue, sender: viewController)
            }
        }
        presentActionSheet(on: viewController, title: nil, message: nil, actions: [startOver, resume, cancelAction])
    }
}
