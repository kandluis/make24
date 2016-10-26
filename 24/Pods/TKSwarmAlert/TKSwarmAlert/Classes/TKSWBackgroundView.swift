//
//  SWBackgroundView.swift
//  blurTest
//
//  Created by Takuya Okamoto on 2015/08/17.
//  Copyright (c) 2015年 Uniface. All rights reserved.
//


//
//  SWBackgroundView.swift
//  blurTest
//
//  Created by Takuya Okamoto on 2015/08/17.
//  Copyright (c) 2015年 Uniface. All rights reserved.
//


import UIKit

public enum TKSWBackgroundType {
    case Blur
    case BrightBlur
    case TransparentBlack(alpha: CGFloat)
}



class TKSWBackgroundView: UIView {
    
    
    let transparentBlackView = UIView()
    var brightView: BrightView?
    
    var blurView: UIVisualEffectView?
    
    
    var blackAlphaForBlur:CGFloat = 0.125
    var blurDuration: TimeInterval = 0.2
    let type: TKSWBackgroundType
    
    init(frame:CGRect, type: TKSWBackgroundType) {
        self.type = type
        super.init(frame:frame)
        self.isHidden = true
        
        transparentBlackView.frame = frame
        transparentBlackView.backgroundColor = UIColor.black
        transparentBlackView.alpha = 0
        self.addSubview(transparentBlackView)
        
        switch type {
        case .Blur, .BrightBlur:
            blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            blurView?.frame = frame
            self.addSubview(blurView!)
            blurView?.alpha = 0
            break
        case .TransparentBlack:
            break
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func show(duration duration:TimeInterval = 0.2, didEnd:(()->Void)? = nil) {
        if duration != 0.2 {
            self.blurDuration = duration
        }
        switch type {
        case .Blur:
            showBlur(didEnd: didEnd)
        case .BrightBlur:
            showBrightBlur(didEnd: didEnd)
        case let .TransparentBlack(alpha):
            self.blackAlphaForBlur = alpha
            showTransparentBlack(didEnd: didEnd)
        }
    }
    
    
    func showTransparentBlack(didEnd:(()->Void)? = nil) {
        self.isHidden = false
        UIView.animate(withDuration: blurDuration) {
            self.transparentBlackView.alpha = self.blackAlphaForBlur
        }
//        Timer.schedule(delay: blurDuration + 0.1) { timer in
//            didEnd?()
//        }
    }
    
    func showBlur(didEnd:(()->Void)? = nil) {
        self.isHidden = false
        self.blurView?.alpha = 0
        UIView.animate(withDuration: blurDuration) {
            self.blurView?.alpha = 1
            self.transparentBlackView.alpha = 0.15
        }
//        Timer.schedule(delay: blurDuration + 0.1) { timer in
//            didEnd?()
//        }
    }
    
    func showBrightBlur(didEnd:(()->Void)? = nil) {
        self.brightView = BrightView(frame: self.frame, center: CGPoint(x: self.center.x, y: self.center.y))
        self.insertSubview(brightView!, aboveSubview: blurView!)
        showBlur() {
            self.brightView?.rotateAnimation()
            didEnd?()
        }
    }
}
