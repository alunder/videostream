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
    
    let reachability = Reachability()!
    
    var video: Video?
    var videoInfo: VideoInfo?
    var downloadState: DownloadState?
    var downloadTask: DownloadTask?
    var thumbnailImage: UIImage?
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    var initialOffsetIgnored = false
    var top: CGFloat?
    
    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBOutlet weak var infoScrollView: UIScrollView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var downloadButton: ProgressButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("Could not start reachability notifier")
        }
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if video?.lastPlayedTime != nil && SettingsManager.shared.resumePlayback {
            playButton.setTitle("Resume", for: .normal)
            if playButton.gestureRecognizers == nil {
                let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(presentPlaybackOptions))
                playButton.addGestureRecognizer(recognizer)
            }
        } else {
            playButton.setTitle("Play", for: .normal)
        }
    }
    
    @objc func updateUI() {
        infoScrollView.delaysContentTouches = false
        infoScrollView.delegate = self
        
        doneButton.layer.shadowColor = UIColor.darkGray.cgColor
        doneButton.layer.shadowOpacity = 0.8;
        doneButton.layer.shadowRadius = 3;
        doneButton.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        
        playButton.isEnabled = true
        playButton.backgroundColor = Colors.buttonColor
        playButton.setTitleColor(Colors.theme, for: .normal)
        playButton.layer.cornerRadius = 5
        playButton.layer.masksToBounds = true
        playButton.setBackgroundColor(color: .darkGray, forState: .highlighted)
        
        downloadButton.isEnabled = true
        downloadButton.backgroundColor = Colors.buttonColor
        downloadButton.progressColor = Colors.progressColor
        downloadButton.layer.cornerRadius = 5
        downloadButton.layer.masksToBounds = true
        downloadButton.setBackgroundColor(color: .darkGray, forState: .highlighted)
        setDownloadButton()
        
        if let task = DownloadService.shared.getDownloads(withId: video!.url.absoluteString)?.first {
            downloadTask = task
            setDownloadProgress()
            setDownloadCompletion()
        }
        
        let headerView = UIImageView()
        headerView.image = thumbnailImage!.verticalGradient(topColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.5),
                                                            bottomColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0))
        headerView.contentMode = .scaleAspectFill
        infoScrollView.parallaxHeader.view = headerView
        infoScrollView.parallaxHeader.mode = .fill
        infoScrollView.parallaxHeader.height = (infoScrollView.frame.width) * (thumbnailImage!.size.height / thumbnailImage!.size.width)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.size.height {
            case 2436: // iPhone X Height
                infoScrollView.parallaxHeader.minimumHeight = 94
                break
            default:
                infoScrollView.parallaxHeader.minimumHeight = 70
            }
        }
        
        guard let videoInfo = videoInfo, let video = video else {
            return
        }
        
        titleLabel.text = videoInfo.title
        
        var filenameTitle: String
        switch video.type {
        case .url:
            filenameTitle = "Filename"
        case .youtube:
            filenameTitle = "YouTube ID"
        }
        
        filenameLabel.attributedText = attributedString(withTitle: filenameTitle,
                                                        value: videoInfo.filename)
        urlLabel.attributedText = attributedString(withTitle: VideoInfoKeys.url.rawValue,
                                                   value: videoInfo.url.absoluteString)
        durationLabel.attributedText = attributedString(withTitle: VideoInfoKeys.duration.rawValue,
                                                        value: videoInfo.duration)
        
        // Disable play and download buttons if functionality not available
        if reachability.connection == .none && !video.isDownloaded {
            playButton.isEnabled = false
            playButton.setTitleColor(.darkGray, for: .normal)
            downloadButton.isEnabled = false
            downloadButton.setTitleColor(.darkGray, for: .normal)
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
    
    @objc func presentPlaybackOptions() {
        Alert.presentPlaybackOptions(on: self)
    }
    
    func setDownloadProgress() {
        downloadState = .inProgress
        self.downloadTask?.progressHandler = { [weak self] in
            self?.downloadButton.progress = Float($0)
        }
    }
    
    func setDownloadButton() {
        downloadButton.setTitleColor(Colors.theme, for: .normal)
        downloadButton.resetProgress()
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
                    try data.write(to: video.filePath, options: [.atomic])
                    DispatchQueue.main.async {
                        self?.downloadState = .downloaded
                        self?.setDownloadButton()
                        if let vc = UIApplication.shared.keyWindow?.rootViewController {
                            Alert.presentDownloadSuccess(on: vc, for: video)
                        }
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
            if FileManager.default.fileExists(atPath: video.filePath.path) {
                downloadState = .downloaded
                Alert.presentDownloadExists(on: self)
            } else {
                downloadButton.isUserInteractionEnabled = false
                downloadState = .inProgress
                setDownloadButton()
                var downloadUrl = video.url
                let dispatchGroup = DispatchGroup()
                
                if video.type == .youtube {
                    dispatchGroup.enter()
                    XCDYouTubeClient.default().getVideoWithIdentifier(video.youtubeID!) { (video, error) in
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
            try FileManager.default.removeItem(at: video!.filePath)
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
