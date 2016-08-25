//
//  VideoTableViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 8/25/16.
//  Copyright © 2016 Ritam Sarmah. All rights reserved.
//

import UIKit

class VideoTableViewController: UITableViewController {
    
    let sampleVideoUrl = "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func addStream(sender: UIBarButtonItem) {
        let videoLinkAlert = UIAlertController(title: "New Video Stream", message: "Enter video streaming link", preferredStyle: .Alert)
        var linkField: UITextField!
        
        // Set up textField to enter link
        videoLinkAlert.addTextFieldWithConfigurationHandler { (textField) in
            textField.text = self.sampleVideoUrl // FIXME: Switch to http://
            textField.addTarget(self, action: #selector(VideoTableViewController.textChanged(_:)), forControlEvents: .EditingChanged)
            linkField = textField
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        videoLinkAlert.addAction(cancelAction)
        let downloadAction = UIAlertAction(title: "Download", style: .Default) { (action) in
            self.downloadVideo()
        }
        videoLinkAlert.addAction(downloadAction)
        downloadAction.enabled = true // FIXME: Switch to false
        
        presentViewController(videoLinkAlert, animated: true, completion: nil)

    }
    
    func textChanged(sender: AnyObject) {
        let tf = sender as! UITextField
        var resp: UIResponder = tf
        while !(resp is UIAlertController) { resp = resp.nextResponder()! }
        let alert = resp as? UIAlertController
        (alert!.actions[1] as UIAlertAction).enabled = (tf.text != "")
    }
    
    private func downloadVideo() {
        print("Downloading video")
    }


}

