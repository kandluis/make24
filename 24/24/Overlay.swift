//
//  Overlay.swift
//  24
//
//  Created by Luis Perez on 11/2/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit

open class LoadingOverlay {
    
    var overlayView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    class var shared: LoadingOverlay {
        struct Static {
            static let instance: LoadingOverlay = LoadingOverlay()
        }
        return Static.instance
    }
    
    open func showOverlay(_ view: UIView) {
        if !activityIndicator.isAnimating {
            overlayView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            overlayView.center = view.center
            overlayView.backgroundColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:0.7)
            overlayView.clipsToBounds = true
            overlayView.layer.cornerRadius = 10
            
            activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            activityIndicator.activityIndicatorViewStyle = .whiteLarge
            activityIndicator.center = CGPoint(x: overlayView.bounds.width / 2, y: overlayView.bounds.height / 2)
            
            overlayView.addSubview(activityIndicator)
            view.addSubview(overlayView)
            
            activityIndicator.startAnimating()
        }
    }
    
    open func hideOverlayView() {
        if activityIndicator.isAnimating {
            activityIndicator.stopAnimating()
            overlayView.removeFromSuperview()
        }
    }
}
