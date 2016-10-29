//
//  CommonFunctions.swift
//  24
//
//  Created by Belinda Zeng on 10/28/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit

let APP_ID = "id959379869"
/***********
 * Share Options
 ***********/
func shareApp(view: UIViewController, message: String) {
    var objectsToShare = [Any]()
    if let myWebsite = URL(string: "http://www.codingexplorer.com/") {
        objectsToShare = [message, myWebsite]
    }
    else {
        objectsToShare = [message]
    }
    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
    //New Excluded Activities Code
    activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
    // activityVC.popoverPresentationController?.sourceView = sender as! UIView
    view.present(activityVC, animated: true, completion: nil)
    if let congratulationsView = view as? CongratulationsViewController {
        activityVC.completionWithItemsHandler = { activity, success, items, error in
            congratulationsView.dismissView()
        }
    }
}
/***********
 * Rate Options
 ***********/
func rateApp() {
    // TODO test this
    let url_string = "https://www.youtube.com/watch?v=6dAL9ztYRqQ"
//    let url_string = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(APP_ID)"
    if let url = NSURL(string: url_string) {
        UIApplication.shared.openURL(url as URL)
    }
}
