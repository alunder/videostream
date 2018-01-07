//
//  AppDelegate.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVFoundation

let themeColor = UIColor.orange //UIColor(red: 199/255, green: 0/255, blue: 57/255, alpha: 1.0)

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
        UserDefaults.standard.register(defaults: [SettingsConstants.Speed : 1.0])
        UserDefaults.standard.register(defaults: [SettingsConstants.ResumePlayback : true])
        
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
        UITableViewCell.appearance().tintColor = themeColor
        UINavigationBar.appearance().tintColor = themeColor
        UIToolbar.appearance().tintColor = themeColor
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        
        return true
    }
    
}

