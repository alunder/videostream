//
//  ProgressButton.swift
//  VideoStreamer
//
//  Created by SARMAH, RITAM on 8/9/18.
//  Copyright © 2018 Ritam Sarmah. All rights reserved.
//

import UIKit

class ProgressButton: UIButton {
    
    var progressColor: UIColor = .darkGray
    var progressLayer: CAGradientLayer?
    
    /*
     *  Set progress using download task
     *
     *  Example:
     *  self.downloadTask?.progressHandler = { [weak self] in
     *      progressButton.progress = Float($0)
     *  }
     */
    var progress: Float = 0 {
        didSet {
            progressLayer?.removeFromSuperlayer()
            
            if progress != 0 {
                let layer = CAGradientLayer()
                layer.frame.size = frame.size
                layer.startPoint = CGPoint.zero
                layer.endPoint = CGPoint(x: 1, y: 0)
                layer.colors = [progressColor, progressColor, backgroundColor, backgroundColor].map { $0!.cgColor }
                layer.locations = [0.0, NSNumber(value: progress), NSNumber(value: progress), 1.0]
                
                progressLayer = layer
                self.layer.insertSublayer(layer, at: 0)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .gray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func resetProgress() {
        progress = 0
    }
}
