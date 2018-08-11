//
//  SettingsManager.swift
//  VideoStreamer
//
//  Created by SARMAH, RITAM on 8/9/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import Foundation

class SettingsManager {
    
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    var playbackSpeed: Float {
        get {
            return defaults.float(forKey: SettingsConstants.Speed)
        }
        set {
            if SettingsConstants.Speeds.index(of: playbackSpeed) != nil {
                defaults.set(newValue, forKey: SettingsConstants.Speed)
            }
        }
    }
    
    var resumePlayback: Bool {
        get {
            return defaults.bool(forKey: SettingsConstants.ResumePlayback)
        }
        set {
            defaults.set(newValue, forKey: SettingsConstants.ResumePlayback)
        }
    }
    
    var backgroundPlay: Bool {
        get {
            return defaults.bool(forKey: SettingsConstants.BackgroundPlay)
        }
        set {
            defaults.set(newValue, forKey: SettingsConstants.BackgroundPlay)
        }
    }
    
    func registerDefaults() {
        UserDefaults.standard.register(defaults: [SettingsConstants.Speed : 1.0])
        UserDefaults.standard.register(defaults: [SettingsConstants.ResumePlayback : true])
        UserDefaults.standard.register(defaults: [SettingsConstants.BackgroundPlay : false])
    }
}
