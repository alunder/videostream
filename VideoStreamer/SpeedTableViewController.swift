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
    let speeds: [Float] = [0.25, 0.5, 1.0, 1.25, 1.5, 2.0]
    var speedIndex: Int = 2 { // Row index 2 corresponds with Normal speed
        didSet {
            if oldValue != speedIndex {
                defaults.set(speeds[speedIndex], forKey: SettingsConstants.Speed)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Speed"
        if let speed = defaults.object(forKey: SettingsConstants.Speed) as? Float {
            speedIndex = speeds.index(of: speed)!
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.cellForRow(at: IndexPath(row: speedIndex, section: 0))!.accessoryType = .checkmark
    }
    
    fileprivate func resetChecks() {
        for row in 0..<speeds.count {
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) {
                cell.accessoryType = .none
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return speeds.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "SpeedCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.textLabel?.text = String(speeds[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        resetChecks()
        speedIndex = indexPath.row
        tableView.cellForRow(at: IndexPath(row: speedIndex, section: 0))!.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
