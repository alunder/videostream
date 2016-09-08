//
//  SpeedTableViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/31/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit

class SpeedTableViewController: UITableViewController {
    
    let defaults = UserDefaults.standard
    var rowForSelectedSpeed: Int = 2 { // Row index 2 corresponds with Normal speed
        didSet {
            if oldValue != rowForSelectedSpeed {
                switch rowForSelectedSpeed {
                case 0: defaults.set(0.25, forKey: SettingsConstants.Speed)
                case 1: defaults.set(0.5, forKey: SettingsConstants.Speed)
                case 2: defaults.set(1.0, forKey: SettingsConstants.Speed)
                case 3: defaults.set(1.25, forKey: SettingsConstants.Speed)
                case 4: defaults.set(1.5, forKey: SettingsConstants.Speed)
                case 5: defaults.set(2.0, forKey: SettingsConstants.Speed)
                default: defaults.set(1.0, forKey: SettingsConstants.Speed)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Speed"
        if let speed = defaults.object(forKey: SettingsConstants.Speed) as? Float {
            switch speed {
            case 0.25: rowForSelectedSpeed = 0
            case 0.5: rowForSelectedSpeed = 1
            case 1.0: rowForSelectedSpeed = 2
            case 1.25: rowForSelectedSpeed = 3
            case 1.5: rowForSelectedSpeed = 4
            case 2.0: rowForSelectedSpeed = 5
            default: rowForSelectedSpeed = 2
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tableView.cellForRow(at: IndexPath(row: rowForSelectedSpeed, section: 0))!.accessoryType = .checkmark
    }
    
    fileprivate func resetChecks() {
        for row in 0...5 {
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) {
                cell.accessoryType = .none
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        resetChecks()
        rowForSelectedSpeed = indexPath.row
        tableView.cellForRow(at: IndexPath(row: rowForSelectedSpeed, section: 0))!.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
