//
//  AppDelegate.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var backgroundCompletionHandler: (() -> Void)?
    var window: UIWindow?
    var imagesDirectoryPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        let cachesDirectoryPath = paths[0] as String
        return cachesDirectoryPath + "/Thumbnails"
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Default settings
        SettingsManager.shared.registerDefaults()
        
        // Create thumbnails directory
        var objcBool: ObjCBool = true
        if !FileManager.default.fileExists(atPath: imagesDirectoryPath, isDirectory: &objcBool) {
            do {
                try FileManager.default.createDirectory(atPath: imagesDirectoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        
        // Color themes
        UITableViewCell.appearance().tintColor = Colors.theme
        UINavigationBar.appearance().tintColor = Colors.theme
        UIToolbar.appearance().tintColor = Colors.theme
        UISwitch.appearance().onTintColor = Colors.theme
        self.window?.tintColor = Colors.theme
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        
        return true
    }
    
}

