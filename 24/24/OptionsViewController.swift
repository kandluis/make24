//
//  OptionsViewController.swift
//  24
//
//  Created by Luis Perez on 10/8/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {

    @IBOutlet weak var shareImage: UIImageView!
    
    @IBOutlet weak var soundImage: UIImageView!
    
    // Settings
    let defaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load settings
        loadSettings()
        
        // Share Image
        shareImage.userInteractionEnabled = true
        shareImage.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(share)))
        
        // Back Button Color
        self.navigationController?.navigationBar.tintColor = UIColor.blueColor();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func toggleAudio(sender: AnyObject) {
        var silent = defaults.boolForKey("silent")
        if !silent {
            silent = true
            soundImage.image = UIImage(named: "mute_grey")
        }
        else {
            silent = false
            soundImage.image = UIImage(named: "sound_grey")
        }
        defaults.setBool(silent, forKey: "silent")
    }
    
    func share(sender: AnyObject) {
        let textToShare = "Swift is awesome!  Check out this website about it!"
        
        if let myWebsite = NSURL(string: "http://www.codingexplorer.com/") {
            let objectsToShare = [textToShare, myWebsite]
            // could create own custom share function (instead of setting nil)
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            //New Excluded Activities Code
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            
            // For iPad
            activityVC.popoverPresentationController?.sourceView = sender as? UIView
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
        
    }
    
    func loadSettings() {
        let silent = defaults.boolForKey("silent")
        if (silent)
        {
            
        }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
