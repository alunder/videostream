//
//  AppDelegate.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit
import AVFoundation

let themeColor = UIColor.red

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
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
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

