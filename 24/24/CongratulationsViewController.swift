//
//  CongratulationsViewController.swift
//  24
//
//  Created by Eden on 10/13/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit

class CongratulationsViewController: UIViewController {
    
    // Settings
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // level related variables
    var level = 0
    var puzzles = 0
    
    let PUZZLES_PER_LEVEL = 10
    // title label
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // congratulations view variables
    @IBOutlet weak var congratulationsView: UIView!
    @IBOutlet weak var star1: UIImageView!
    @IBOutlet weak var star2: UIImageView!
    @IBOutlet weak var star3: UIImageView!
    @IBOutlet weak var star4: UIImageView!
    @IBOutlet weak var star5: UIImageView!
    @IBOutlet weak var star6: UIImageView!
    @IBOutlet weak var star7: UIImageView!
    @IBOutlet weak var star8: UIImageView!
    @IBOutlet weak var star9: UIImageView!
    @IBOutlet weak var star10: UIImageView!
    var stars = [UIImageView]()
    @IBOutlet weak var congratulationsButton: UIButton!
    var congratulations_variables = [UIView]()
    
    // beat level view variables
    @IBOutlet weak var trophyImage: UIImageView!
    @IBOutlet weak var levelLabel: UILabel!
    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var nextLevelButton: UIButton!
    var beat_level_variables = [UIView]()
    var alert = "beat_level"
    
    // lose level variables
    @IBOutlet weak var tryAgainButton: UIButton!
    @IBOutlet weak var loseImage: UIImageView!
    var lose_variables = [UIView]()
    
    // view animation related variables
    var animator:UIDynamicAnimator? = nil;
    let gravity = UIGravityBehavior()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // create the stars array
        stars = [star1, star2, star3, star4, star5, star6, star7, star8, star9, star10]
        congratulations_variables = [congratulationsButton] + stars
        
        beat_level_variables = [trophyImage, levelLabel, leaderboardButton, nextLevelButton]
        
        lose_variables = [tryAgainButton, loseImage]
        
        alert = getScore()
        
        if alert == "congratulations" {
            hideObjects(beat_level_variables + lose_variables)
        }
        else if alert == "beat_level" {
            hideObjects(congratulations_variables + lose_variables)
            
        }
        else {
            hideObjects(congratulations_variables + beat_level_variables)
        }
    }
    
    func getScore() -> String {
        if let alert_type = defaults.objectForKey("alert") as? String {
            if alert_type == "congratulations" {
                let score = defaults.integerForKey("score")
                
                puzzles = score%PUZZLES_PER_LEVEL
                
                level = Int((score - puzzles)/PUZZLES_PER_LEVEL)
                
                if score%PUZZLES_PER_LEVEL == 0 {
                    return "beat_level"
                }
            
                return "congratulations"
            }
        }
        return "lose"
    }
    
    func lose() {
        titleLabel.text = "Aww snap!"
        
    }
    
    func beat_level() {
        titleLabel.text = "You beat level " + String(level) + "!"
//        animateImageView(trophyImage)
        levelLabel.text = String(level)
//        levelLabel.hidden = false
        
        
    }
    
    func congratulations() {
        titleLabel.text = "Congrats!"
        showStars()
        
        for star_index in 0..<puzzles {
            let star = stars[star_index]
            animateImageView(star, filename: "colored_star")
            // make some sound effect
        }
        
        
//        congratulationsButton.titleLabel?.text = "Keep Going"
    }
    
    func showStars() {
        for star in stars {
            star.hidden=false
        }
        
    }
    func animateImageView(image: UIImageView, filename: String) {
        if let new_image = UIImage(named: filename) {
            // animate the new star
            image.animationImages = [new_image]
            image.animationDuration = 1.0
            image.startAnimating()
        }
    
        // play sound effect
    }
    
    func hideObjects(objects: [UIView]) {
        for el in objects {
            el.hidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // more code
    }
    
    func snapToPoint(point: CGPoint, view: UIView) {
        let snap = UISnapBehavior(item: view, snapToPoint: point)
        animator?.addBehavior(snap);
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // snap the alert to middle of screen
        animator = UIDynamicAnimator(referenceView:self.view);
        let x = view.frame.size.width / 2
        let y = view.frame.size.height / 2
        let point = CGPoint(x: x, y: y)
        snapToPoint(point, view: congratulationsView)
        if alert == "congratulations" {
            congratulations()
        }
        else if alert == "beat_level" {
            beat_level()
        }
        else {
            lose()
        }
        
        // old animation
//        UIView.animateWithDuration(1.5, animations: {
//            self.congratulationsView.alpha = 1.0
////            self.myFirstButton.alpha = 1.0
////            self.mySecondButton.alpha = 1.0
//        })
    }
    
    // maybe wait until animation finishes to dismiss view
    
    @IBAction func dismissCongratulations(sender: AnyObject) {
        gravity.addItem(congratulationsView);
        gravity.gravityDirection = CGVectorMake(0, 0.8)
        animator = UIDynamicAnimator(referenceView:self.view);
        animator?.addBehavior(gravity)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
