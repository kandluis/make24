//
//  CongratulationsViewController.swift
//  24
//
//  Created by Eden on 10/13/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit

// Type of Alerts
enum AlertType {
    case finish
    case next_difficulty
    case next_puzzle
    case next_level
    case retry
    case rate
}

// The types of actions the user can initiate from this ViewController.
enum UserAction {
    case rate
    case keepGoing
    case challange
    case nextLevel
    case leaderboard
    case dismiss
    case retry
    case ask
    
}

class CongratulationsViewController: UIViewController {
    // User defaults
    fileprivate let defaults = UserDefaults.standard
    
    // level related variables
    fileprivate var difficulty: GameDifficulty = GameDifficulty.easy
    fileprivate var level: Int = 0
    fileprivate var puzzles: Int = 0
    fileprivate var type: AlertType = AlertType.next_level
    fileprivate var primary_action: UserAction?
    fileprivate var secondary_action: UserAction?
    
    // Access to starting/stopping the sound
    fileprivate var completion: ((AlertType, UserAction?) -> Void)!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // buttons in common
    @IBOutlet weak var secondaryButton: UIButton!
    @IBOutlet weak var primaryButton: UIButton!
    // rate variables
    @IBOutlet weak var rateImage: UIImageView!
    var rate_variables = [UIView]()
    
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
    var congratulations_variables = [UIView]()
    
    // beat level view variables
    @IBOutlet weak var trophyImage: UIImageView!
    @IBOutlet weak var levelLabel: UILabel!
    var beat_level_variables = [UIView]()
    
    // lose level variables
    @IBOutlet weak var loseImage: UIImageView!
    var lose_variables = [UIView]()
    
    // view animation related variables
    fileprivate var animator:UIDynamicAnimator? = nil;
    fileprivate let gravity = UIGravityBehavior()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // create the stars array
        stars = [star1, star2, star3, star4, star5, star6, star7, star8, star9, star10]
        congratulations_variables = stars
        
        beat_level_variables = [trophyImage, levelLabel]
        
        lose_variables = [loseImage]
        
        rate_variables = [rateImage]
        
        switch type {
        case AlertType.next_level:
            hideObjects(congratulations_variables + lose_variables + rate_variables)
        case AlertType.next_puzzle:
            hideObjects(beat_level_variables + lose_variables + rate_variables)
        case AlertType.retry:
            hideObjects(congratulations_variables + beat_level_variables + rate_variables)
        case AlertType.next_difficulty, AlertType.finish:
            hideObjects(congratulations_variables + lose_variables + rate_variables)
        case AlertType.rate:
            hideObjects(congratulations_variables + lose_variables + beat_level_variables)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // snap the alert to middle of screen
        animator = UIDynamicAnimator(referenceView:self.view);
        let x = view.frame.size.width / 2
        let y = view.frame.size.height / 2
        let point = CGPoint(x: x, y: y)
        snapToPoint(point, view: congratulationsView)
        switch type {
        case AlertType.next_puzzle:
            congratulations()
        case AlertType.next_level, AlertType.next_difficulty, AlertType.finish:
            beat_level()
        case AlertType.retry:
            lose()
        case AlertType.rate:
            rate()
        }
    }
    
    // Completion is passed the String corresponding to the
    // button the user clicked, if any.
    open func setOptions(alert alert_type: AlertType, currentDifficulty difficulty: GameDifficulty, currentLevel level: Int, puzzlesSolved puzzles: Int, completion: @escaping ((AlertType, UserAction?) -> Void)) -> () {
        self.type = alert_type
        self.difficulty = difficulty
        self.level = level
        self.puzzles = puzzles
        self.completion = completion
    }
    
    fileprivate func lose() {
        let loseMessage = NSLocalizedString("Aww snap!", comment: "friendly lose message in alert")
        titleLabel.text = loseMessage
        primaryButton.setTitle(NSLocalizedString("Try Again", comment: "lose alert try again"), for: UIControlState())
        primary_action = .retry
        secondaryButton.setTitle(NSLocalizedString("Ask A Friend", comment: "lose alert ask a friend"), for: UIControlState())
        secondary_action = .ask
    }
    
    fileprivate func congratulations() {
        let congratsMessage = NSLocalizedString("Congrats!", comment: "friendly congrats message in alert")
        
        titleLabel.text = congratsMessage
        
        showStars()
        
        for star_index in 0..<puzzles {
            let star = stars[star_index]
            animateImageView(star, filename: "colored_star", duration: 1.0, delay: Double(star_index) * 1.0)
            // TODO: make some sound effect
        }
        
        primaryButton.setTitle(NSLocalizedString("Keep Going", comment: "congrats alert keep going"), for: UIControlState())
        primary_action = UserAction.keepGoing
        secondaryButton.setTitle(NSLocalizedString("Challenge", comment: "congrats alert challange"), for: UIControlState())
        secondary_action = UserAction.challange
    }
    
    fileprivate func beat_level() {
        let winMessage = NSLocalizedString("You beat level ", comment: "friendly beat level message in alert")
        var modeMessage = ""
        switch difficulty {
            case .easy:
                modeMessage = NSLocalizedString("on easy mode!", comment: "beat level on easy mode")
            case .medium:
                modeMessage = NSLocalizedString("on medium mode!", comment: "beat level on medium mode")
            case .hard:
                modeMessage = NSLocalizedString("on hard mode!", comment: "beat level on hard mode")
        }
        titleLabel.text = winMessage + String(level) + " " + modeMessage
        animateImageView(trophyImage, filename: "trophy", duration: 1.0, delay: 0)
        levelLabel.text = String(level)
        primaryButton.setTitle(NSLocalizedString("Next Level", comment: "beat level alert next level"), for: UIControlState())
        primary_action = UserAction.nextLevel
        secondaryButton.setTitle(NSLocalizedString("Leaderboard", comment: "beat level alert leaderboard"), for:UIControlState())
        secondary_action = UserAction.leaderboard

        
    }
    
    fileprivate func rate() {
        let rateMessage = NSLocalizedString("Enjoying the game?", comment: "friendly rate message in alert")
        titleLabel.text = rateMessage
        primaryButton.setTitle(NSLocalizedString("Not Now", comment: "rate alert not now"), for: UIControlState())
        primary_action = UserAction.dismiss
        secondaryButton.setTitle(NSLocalizedString("Rate the App", comment: "rate alert rate the app"), for: UIControlState())
        secondary_action = UserAction.rate
    }
    
    fileprivate func showStars() {
        for star in stars {
            star.isHidden=false
        }
        
    }
    fileprivate func animateImageView(_ image: UIImageView, filename: String, duration: TimeInterval, delay: TimeInterval) {
        if let new_image = UIImage(named: filename) {
            // animate the new star
            image.animationImages = [new_image]
            image.animationDuration = duration
            image.startAnimating()
        }
        // play sound effect
    }
    
    fileprivate func hideObjects(_ objects: [UIView]) {
        for el in objects {
            el.isHidden = true
        }
    }
    
    fileprivate func snapToPoint(_ point: CGPoint, view: UIView) {
        let snap = UISnapBehavior(item: view, snapTo: point)
        animator?.addBehavior(snap);
    }
    
    // Primary action!
    @IBAction func dismissCongratulations(_ sender: AnyObject) {
        dismissView(self.primary_action)
    }
    @IBAction func secondaryAction(_ sender: Any) {
        dismissView(self.secondary_action)
    }
    
    fileprivate func dismissView(_ action: UserAction?) {
        gravity.addItem(congratulationsView);
        gravity.gravityDirection = CGVector(dx: 0, dy: 0.8)
        animator = UIDynamicAnimator(referenceView:self.view);
        animator?.addBehavior(gravity)
        self.dismiss(animated: true, completion: {[unowned self] in
            if let code = self.completion {
                code(self.type, action)
            }
        })
    }
    
    
}
