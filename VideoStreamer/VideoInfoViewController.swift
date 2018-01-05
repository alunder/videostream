//
//  VideoInfoViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 1/4/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import UIKit
import MXParallaxHeader

class VideoInfoViewController: UIViewController {
    
    var video: Video?
    var videoInfo: [String: Any]?
    var thumbnailImage: UIImage?
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBOutlet weak var infoScrollView: UIScrollView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        infoScrollView.delaysContentTouches = false
        
        doneButton.layer.shadowColor = UIColor.darkGray.cgColor
        doneButton.layer.shadowOpacity = 0.8;
        doneButton.layer.shadowRadius = 3;
        doneButton.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        
        let backgroundColor = UIColor(red: 229/255, green: 229/255, blue: 239/255, alpha: 1.0)
        playButton.backgroundColor = backgroundColor
        playButton.setTitleColor(themeColor, for: .normal)
        playButton.layer.cornerRadius = 5
        playButton.layer.masksToBounds = true
        playButton.setBackgroundColor(color: .darkGray, forState: .highlighted)
        
        downloadButton.backgroundColor = backgroundColor
        downloadButton.setTitleColor(themeColor, for: .normal)
        downloadButton.layer.cornerRadius = 5
        downloadButton.layer.masksToBounds = true
        downloadButton.setBackgroundColor(color: .darkGray, forState: .highlighted)
        
        let headerView = UIImageView()
        headerView.image = imageWithGradient(img: thumbnailImage!)
        headerView.contentMode = .scaleAspectFill
        
        infoScrollView.parallaxHeader.view = headerView
        infoScrollView.parallaxHeader.mode = .fill
        infoScrollView.parallaxHeader.height = view.frame.height/3
        infoScrollView.parallaxHeader.minimumHeight = infoScrollView.parallaxHeader.height
        
        if let videoInfo = videoInfo {
            titleLabel.text = videoInfo[VideoInfoKeys.Title] as? String
            let filenameTitle = (video?.isYouTube)! ? "YouTube ID" : "Filename"
            filenameLabel.attributedText = attributedString(withTitle: filenameTitle,
                                                            value: videoInfo[VideoInfoKeys.Filename]! as! String)
            urlLabel.attributedText = attributedString(withTitle: VideoInfoKeys.URL,
                                                       value: videoInfo[VideoInfoKeys.URL]! as! String )
            durationLabel.attributedText = attributedString(withTitle: VideoInfoKeys.Duration,
                                                            value: videoInfo[VideoInfoKeys.Duration] as! String)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.PlayerFromInfoSegue {
            if let playervc = segue.destination as? PlayerViewController {
                playervc.video = self.video
            }
        }
    }
    
    
    @IBAction func donePressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func downloadPressed(_ sender: UIButton) {
        print("download tapped")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        infoScrollView.parallaxHeader.height = size.height/3
        infoScrollView.parallaxHeader.minimumHeight = infoScrollView.parallaxHeader.height
    }
    
    func imageWithGradient(img: UIImage) -> UIImage {
        UIGraphicsBeginImageContext(img.size)
        let context = UIGraphicsGetCurrentContext()
        
        img.draw(at: CGPoint(x: 0, y: 0))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        let top = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).cgColor
        let bottom = UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor
        let colors = [top, bottom] as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)
        
        let startPoint = CGPoint(x: img.size.width/2, y: 0)
        let endPoint = CGPoint(x: img.size.width/2, y: img.size.height)
        
        context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func attributedString(withTitle title: String, value: String) -> NSMutableAttributedString {
        let boldFont = UIFont.boldSystemFont(ofSize: 17.0)
        let labelString = NSMutableAttributedString(string: title + "\n", attributes: [.font : boldFont])
        
        let regularFont = UIFont.systemFont(ofSize: 17.0)
        let regularAttributes: Dictionary<NSAttributedStringKey, Any> = [.font : regularFont,
                                                                         .foregroundColor : UIColor.darkGray]
        let valueString = NSMutableAttributedString(string: value, attributes: regularAttributes)
        
        labelString.append(valueString)
        return labelString
    }
    
    func deleteVideo() {
        do {
            try FileManager.default.removeItem(at: video!.getFilePath())
        } catch {
            print(error.localizedDescription)
        }
    }
}
