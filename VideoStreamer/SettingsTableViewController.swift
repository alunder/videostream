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
    @IBOutlet weak var labelLeadingConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            labelLeadingConstraint.constant = 0
        } else {
            labelLeadingConstraint.constant = 13
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        speedValueLabel.text = "\(SettingsManager.shared.playbackSpeed)"
        resumePlaybackSwitch.isOn = SettingsManager.shared.resumePlayback
    }
   
    // MARK: - Navigation

    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func resumePlaybackChanged(_ sender: UISwitch) {
        SettingsManager.shared.resumePlayback = sender.isOn
    }
    
}
