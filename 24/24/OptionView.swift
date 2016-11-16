//
//  SWDesignView.swift
//  SWAlertView
//
//  Created by Takuya Okamoto on 2015/08/18.
//  Copyright (c) 2015年 Uniface. All rights reserved.
//

import UIKit


enum OptionViewType {
    case bar(leftIcon:UIImage?, text:String, rightIcon:UIImage?)
}


class OptionView: UIView {
    
    init(type:OptionViewType, frame:CGRect) {
        super.init(frame:frame)
        
        switch type {
        case let .bar(leftIcon, text, rightIcon):
            setupBarDesign(leftIcon, text: text, rightIcon: rightIcon)
        }
    }
    
    func setupBarDesign(_ leftIcon:UIImage?, text:String, rightIcon:UIImage?) {
        self.backgroundColor = UIColor.white
        self.layer.borderWidth = 0
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = 10
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 0.4
        self.layer.shadowRadius = 2.0
        
        let margin:CGFloat = 6
        let size = self.frame.height
        
        if leftIcon != nil {
            let iconView = UIImageView(image: leftIcon)
            iconView.contentMode = UIViewContentMode.center
            iconView.frame = CGRect(x: margin, y: 0, width: size, height: size)
            self.addSubview(iconView)
        }
        
        if rightIcon != nil {
            let iconView = UIImageView(image: rightIcon)
            iconView.contentMode = UIViewContentMode.center
            iconView.frame = CGRect(x: self.frame.width - size - margin, y: 0, width: size, height: size)
            self.addSubview(iconView)
        }
        
        var labelLeft = margin
        if leftIcon != nil {
            labelLeft += (self.frame.height + margin)
        }
        var width = frame.width - labelLeft - margin
        if rightIcon != nil {
            width -= (self.frame.height + margin)
        }
        let label = UILabel()
        label.frame = CGRect(x: labelLeft, y: 0, width: width, height: frame.height)
        label.numberOfLines = 0
        label.text = text
        label.textColor = UIColor(red: 100/255, green: 91/255, blue: 82/255, alpha: 1)
        self.addSubview(label)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
