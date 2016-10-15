//
//  CongratulationsViewController.swift
//  24
//
//  Created by Eden on 10/13/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit

class CongratulationsViewController: UIViewController {
    // Type of Alerts
    enum AlertType {
        case FINISH
        case NEXT_PUZZLE
        case NEXT_LEVEL
        case RETRY
    }

    // level related variables
    private var level: Int = 0
    private var puzzles: Int = 0
    private var type: AlertType = AlertType.NEXT_LEVEL
    
    // Access to starting/stopping the sound
    private var completion: (String? -> Void)!
    
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
        
        switch type {
        case AlertType.NEXT_LEVEL:
            hideObjects(congratulations_variables + lose_variables)
        case AlertType.NEXT_PUZZLE:
            hideObjects(beat_level_variables + lose_variables)
        case AlertType.RETRY:
            hideObjects(congratulations_variables + beat_level_variables)
        case AlertType.FINISH:
            hideObjects(congratulations_variables + lose_variables)
            nextLevelButton.setTitle("Reset", forState: .Normal)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // snap the alert to middle of screen
        animator = UIDynamicAnimator(referenceView:self.view);
        let x = view.frame.size.width / 2
        let y = view.frame.size.height / 2
        let point = CGPoint(x: x, y: y)
        snapToPoint(point, view: congratulationsView)
        switch type {
        case AlertType.NEXT_PUZZLE:
            congratulations()
        case AlertType.NEXT_LEVEL:
            beat_level()
        case AlertType.RETRY:
            lose()
        case AlertType.FINISH:
            beat_level()
        }
    }
    
    // Completion is passed the String corresponding to the
    // button the user clicked, if any.
    func setOptions(alertStringIdentifier alert_type: String, currentLevel level: Int, puzzlesSolved puzzles: Int, completion: ((String?) -> Void)) -> () {
        switch alert_type {
        case "next_level":
            type = AlertType.NEXT_LEVEL
        case "next_puzzle":
            type = AlertType.NEXT_PUZZLE
        case "fail":
            type = AlertType.RETRY
        case "finish":
            type = AlertType.FINISH
        default:
            type = AlertType.RETRY
        }
        
        self.level = level
        self.puzzles = puzzles
        self.completion = completion
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
    
    // maybe wait until animation finishes to dismiss view
    
    @IBAction func dismissCongratulations(sender: AnyObject) {
        gravity.addItem(congratulationsView);
        gravity.gravityDirection = CGVectorMake(0, 0.8)
        animator = UIDynamicAnimator(referenceView:self.view);
        animator?.addBehavior(gravity)
        self.dismissViewControllerAnimated(true, completion: {[unowned self] in
            if self.type == AlertType.FINISH {
                let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
                delegate.resetApplication()
            }
            self.completion!(sender.titleLabel?.text)
        })
    }
    
}
