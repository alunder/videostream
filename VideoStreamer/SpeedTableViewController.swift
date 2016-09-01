//
//  SpeedTableViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/31/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit

class SpeedTableViewController: UITableViewController {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    var rowForSelectedSpeed: Int = 2 { // Row index 2 corresponds with Normal speed
        didSet {
            print(oldValue, "->", rowForSelectedSpeed)
            if oldValue != rowForSelectedSpeed {
                print("Set new defaults value")
                switch rowForSelectedSpeed {
                case 0: defaults.setFloat(0.25, forKey: SettingsConstants.Speed)
                case 1: defaults.setFloat(0.5, forKey: SettingsConstants.Speed)
                case 2: defaults.setFloat(1.0, forKey: SettingsConstants.Speed)
                case 3: defaults.setFloat(1.25, forKey: SettingsConstants.Speed)
                case 4: defaults.setFloat(1.5, forKey: SettingsConstants.Speed)
                case 5: defaults.setFloat(2.0, forKey: SettingsConstants.Speed)
                default: defaults.setFloat(1.0, forKey: SettingsConstants.Speed)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Speed"
        if let speed = defaults.objectForKey(SettingsConstants.Speed) as? Float {
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: rowForSelectedSpeed, inSection: 0))!.accessoryType = .Checkmark
    }
    
    private func resetChecks() {
        for row in 0...5 {
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) {
                cell.accessoryType = .None
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        resetChecks()
        rowForSelectedSpeed = indexPath.row
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: rowForSelectedSpeed, inSection: 0))!.accessoryType = .Checkmark
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}
