//
//  SettingsTableViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/31/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var speedValueLabel: UILabel!
    @IBOutlet weak var resumePlaybackSwitch: UISwitch!
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let speed = defaults.object(forKey: SettingsConstants.Speed)
        speedValueLabel.text = String(describing: speed!)
        let doesResume = defaults.bool(forKey: SettingsConstants.ResumePlayback)
        resumePlaybackSwitch.isOn = doesResume
    }

    struct Storyboard {
        static let SpeedCellIdentifier = "Speed"
    }
   
    // MARK: - Navigation

    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func resumePlaybackChanged(_ sender: UISwitch) {
        defaults.set(sender.isOn, forKey: SettingsConstants.ResumePlayback)
    }
    
}
