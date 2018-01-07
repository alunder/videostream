//
//  VideoInfoViewController.swift
//  VideoStreamer
//
//  Created by Ritam Sarmah on 1/4/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import UIKit
import XCDYouTubeKit
import MXParallaxHeader

class VideoInfoViewController: UIViewController, UIScrollViewDelegate {
    
    var video: Video?
    var videoInfo: [String: Any]?
    var downloadState: DownloadState?
    var downloadTask: DownloadTask?
    var thumbnailImage: UIImage?
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var initialOffsetIgnored = false
    var top: CGFloat?
    
    let buttonColor = UIColor(red: 229/255, green: 229/255, blue: 239/255, alpha: 1.0)
    var progressLayer: CAGradientLayer?
    
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
        print(downloadState.debugDescription)
        infoScrollView.delaysContentTouches = false
        infoScrollView.delegate = self
        
        doneButton.layer.shadowColor = UIColor.darkGray.cgColor
        doneButton.layer.shadowOpacity = 0.8;
        doneButton.layer.shadowRadius = 3;
        doneButton.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        
        playButton.backgroundColor = buttonColor
        playButton.setTitleColor(themeColor, for: .normal)
        playButton.layer.cornerRadius = 5
        playButton.layer.masksToBounds = true
        playButton.setBackgroundColor(color: .darkGray, forState: .highlighted)
        
        downloadButton.backgroundColor = buttonColor
        downloadButton.layer.cornerRadius = 5
        downloadButton.layer.masksToBounds = true
        downloadButton.setBackgroundColor(color: .darkGray, forState: .highlighted)
        setDownloadButton()
        
        let headerView = UIImageView()
        headerView.image = imageWithGradient(img: thumbnailImage!)
        headerView.contentMode = .scaleAspectFill
        
        if let task = DownloadService.shared.getDownloads(withId: video!.url.absoluteString)?.first {
            downloadTask = task
            setDownloadProgress()
            setDownloadCompletion()
        }
        
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
    
    func setDownloadButtonProgress(progress: Float) {
        progressLayer?.removeFromSuperlayer()
        
        let layer = CAGradientLayer()
        layer.frame.size = downloadButton.frame.size
        layer.startPoint = CGPoint.zero
        layer.endPoint = CGPoint(x: 1, y: 0)
        
        let progressColor = UIColor(red: 210/255, green: 210/255, blue: 220/255, alpha: 1.0).cgColor
        let backgroundColor = buttonColor.cgColor
        
        layer.colors = [progressColor, progressColor, backgroundColor, backgroundColor]
        layer.locations = [0.0, NSNumber(value: progress), NSNumber(value: progress), 1.0]
        
        progressLayer = layer
        downloadButton.layer.insertSublayer(layer, at: 0)
    }
    
    func setDownloadProgress() {
        downloadState = .inProgress
        self.downloadTask?.progressHandler = { [weak self] in
            self?.setDownloadButtonProgress(progress: Float($0))
        }
    }
    
    func setDownloadButton() {
        downloadButton.setTitleColor(themeColor, for: .normal)
        progressLayer?.removeFromSuperlayer()
        if let downloadState = self.downloadState {
            switch downloadState {
            case .notDownloaded:
                downloadButton.setTitle("Download", for: .normal)
            case .inProgress:
                downloadButton.setTitle("Cancel", for: .normal)
            case .paused:
                break
            case .downloaded:
                downloadButton.setTitle("Remove", for: .normal)
                downloadButton.setTitleColor(UIColor.red, for: .normal)
            case .disabled:
                downloadButton.isEnabled = false
            }
        }
    }
    
    func setDownloadCompletion() {
        guard let video = self.video else { return }
        downloadTask?.completionHandler = { [weak self] in
            switch $0 {
            case .failure(let error):
                self?.downloadState = .notDownloaded
                self?.setDownloadButton()
                print("Video download failed: \(error.localizedDescription)")
            case .success(let data):
                do {
                    try data.write(to: video.getFilePath(), options: [.atomic])
                    DispatchQueue.main.async {
                        self?.downloadState = .downloaded
                        self?.setDownloadButton()
                        let alert = UIAlertController(title: "Download successful!", message: "\"\(video.title ?? video.filename)\" is now available offline", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                    }
                } catch let error {
                    self?.downloadState = .notDownloaded
                    self?.setDownloadButton()
                    print("Video file save failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func downloadPressed(_ sender: UIButton) {
        guard let video = video else { return }
        
        switch downloadState! {
        case .notDownloaded:
            let destination = video.getFilePath()
            if FileManager.default.fileExists(atPath: destination.path) {
                downloadState = .downloaded
                let downloadAlert = UIAlertController(title: "Video already downloaded!", message: nil, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default, handler: nil)
                downloadAlert.addAction(action)
                present(downloadAlert, animated: true, completion: nil)
            } else {
                downloadButton.isUserInteractionEnabled = false
                downloadState = .inProgress
                setDownloadButton()
                var downloadUrl = video.url
                let dispatchGroup = DispatchGroup()
                if video.isYouTube {
                    dispatchGroup.enter()
                    XCDYouTubeClient.default().getVideoWithIdentifier(video.getYouTubeID()) { (video, error) in
                        if let streamURLs = video?.streamURLs, let streamURL = (streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?? streamURLs[YouTubeVideoQuality.hd720] ?? streamURLs[YouTubeVideoQuality.medium360] ?? streamURLs[YouTubeVideoQuality.small240]) {
                            downloadUrl = streamURL
                        } else {
                            print("Failed to download YouTube video")
                        }
                        dispatchGroup.leave()
                    }
                }
                
                self.downloadButton.isUserInteractionEnabled = false
                dispatchGroup.notify(queue: .global(qos: .background)) {
                    let request = URLRequest(url: downloadUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
                    self.downloadTask = DownloadService.shared.download(request: request, withId: video.url.absoluteString)
                    self.setDownloadCompletion()
                    DispatchQueue.main.async {
                        self.downloadButton.isUserInteractionEnabled = true
                        self.setDownloadProgress()
                        self.setDownloadButton()
                    }
                    self.downloadTask?.resume()
                }
            }
        case .inProgress:
            downloadState = .notDownloaded
            setDownloadButton()
            downloadTask?.cancel()
        case .downloaded:
            downloadState = .notDownloaded
            VideoInfoManager.shared.deleteDownload(forVideo: self.video!)
            setDownloadButton()
        default:
            break
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        infoScrollView.parallaxHeader.height = size.height/3
        infoScrollView.parallaxHeader.minimumHeight = infoScrollView.parallaxHeader.height
        top = infoScrollView.contentOffset.y + infoScrollView.contentInset.top // TODO: switch to size value
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
    
    // MARK: UIScrollView
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let relativeYOffset = scrollView.contentOffset.y + scrollView.contentInset.top
        if !initialOffsetIgnored {
            initialOffsetIgnored = true
            return
        }
        
        if top == nil {
            top = relativeYOffset
        } else {
            if relativeYOffset < top! - 60 {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
