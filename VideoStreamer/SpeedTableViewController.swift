//
//  SpeedTableViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/31/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit

class SpeedTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Speed"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let index = SettingsConstants.Speeds.index(of: SettingsManager.shared.playbackSpeed)!
        let row = SettingsConstants.Speeds.distance(from: 0, to: index)
        tableView.cellForRow(at: IndexPath(row: row, section: 0))!.accessoryType = .checkmark
    }
    
    func resetChecks() {
        for row in 0..<SettingsConstants.Speeds.count {
            if let cell = tableView.cellForRow(at: IndexPath(row: row, section: 0)) {
                cell.accessoryType = .none
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SettingsConstants.Speeds.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "SpeedCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        cell.textLabel?.text = String(SettingsConstants.Speeds[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        resetChecks()
        SettingsManager.shared.playbackSpeed = SettingsConstants.Speeds[indexPath.row]
        tableView.cellForRow(at: IndexPath(row: indexPath.row, section: 0))!.accessoryType = .checkmark
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
