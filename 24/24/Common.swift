//
//  CommonFunctions.swift
//  24
//
//  Created by Belinda Zeng on 10/28/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit
import iRate

let APP_ID = "1200346468"

class Common {
    class func shareApp(fromController view: UIViewController, message: String) {
        var objectsToShare = [Any]()
        if let myWebsite = URL(string: "itms://itunes.apple.com/us/app/apple-store/id\(APP_ID)") {
            objectsToShare = [message, myWebsite]
        }
        else {
            objectsToShare = [message]
        }
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        //New Excluded Activities Code
        activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
        view.present(activityVC, animated: true, completion: nil)
    }

    class func rateApp() {
        iRate.sharedInstance().openRatingsPageInAppStore()
    }
    
    static let ENABLE_ADS = true
}
