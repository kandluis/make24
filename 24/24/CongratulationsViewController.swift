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
        case finish
        case next_puzzle
        case next_level
        case retry
    }

    // level related variables
    fileprivate var level: Int = 0
    fileprivate var puzzles: Int = 0
    fileprivate var type: AlertType = AlertType.next_level
    
    // Access to starting/stopping the sound
    fileprivate var completion: ((String?) -> Void)!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    // buttons in common
    @IBOutlet weak var secondaryButton: UIButton!
    @IBOutlet weak var primaryButton: UIButton!
    
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
    var animator:UIDynamicAnimator? = nil;
    let gravity = UIGravityBehavior()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // create the stars array
        stars = [star1, star2, star3, star4, star5, star6, star7, star8, star9, star10]
        congratulations_variables = stars
        
        beat_level_variables = [trophyImage, levelLabel]
        
        lose_variables = [loseImage]
        
        switch type {
        case AlertType.next_level:
            hideObjects(congratulations_variables + lose_variables)
        case AlertType.next_puzzle:
            hideObjects(beat_level_variables + lose_variables)
        case AlertType.retry:
            hideObjects(congratulations_variables + beat_level_variables)
        case AlertType.finish:
            hideObjects(congratulations_variables + lose_variables)
            primaryButton.setTitle("Reset", for: UIControlState())
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
        case AlertType.next_level:
            beat_level()
        case AlertType.retry:
            lose()
        case AlertType.finish:
            beat_level()
        }
    }
    
    // Completion is passed the String corresponding to the
    // button the user clicked, if any.
    func setOptions(alertStringIdentifier alert_type: String, currentLevel level: Int, puzzlesSolved puzzles: Int, completion: @escaping ((String?) -> Void)) -> () {
        switch alert_type {
        case "next_level":
            type = AlertType.next_level
        case "next_puzzle":
            type = AlertType.next_puzzle
        case "fail":
            type = AlertType.retry
        case "finish":
            type = AlertType.finish
        default:
            type = AlertType.retry
        }
        
        self.level = level
        self.puzzles = puzzles
        self.completion = completion
    }
    
    func lose() {
        let loseMessage = NSLocalizedString("Aww snap!", comment: "friendly lose message in alert")
        titleLabel.text = loseMessage
        primaryButton.setTitle(NSLocalizedString("Try Again", comment: "lose alert"), for: UIControlState())
        secondaryButton.setTitle(NSLocalizedString("Ask A Friend", comment: "lose alert"), for: UIControlState())
    }
    
    func beat_level() {
        let winMessage = NSLocalizedString("You beat level ", comment: "friendly beat level message in alert")
        titleLabel.text = winMessage + String(level) + "!"
//        animateImageView(trophyImage)
        levelLabel.text = String(level)
//        levelLabel.hidden = false
        primaryButton.setTitle(NSLocalizedString("Next Level", comment: "beat level alert"), for: UIControlState())
        secondaryButton.setTitle(NSLocalizedString("Leaderboard", comment: "beat level alert"), for:UIControlState())

        
    }
    
    func congratulations() {
        let congratsMessage = NSLocalizedString("Congrats!", comment: "friendly congrats message in alert")

        titleLabel.text = congratsMessage
        
        showStars()
        
        for star_index in 0..<puzzles {
            let star = stars[star_index]
            animateImageView(star, filename: "colored_star")
            // make some sound effect
        }
        
        
        primaryButton.setTitle(NSLocalizedString("Keep Going", comment: "congrats alert"), for: UIControlState())
        secondaryButton.setTitle(NSLocalizedString("Challenge", comment: "congrats alert"), for: UIControlState())
    }
    
    func showStars() {
        for star in stars {
            star.isHidden=false
        }
        
    }
    func animateImageView(_ image: UIImageView, filename: String) {
        if let new_image = UIImage(named: filename) {
            // animate the new star
            image.animationImages = [new_image]
            image.animationDuration = 1.0
            image.startAnimating()
        }
    
        // play sound effect
    }
    
    func hideObjects(_ objects: [UIView]) {
        for el in objects {
            el.isHidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // more code
    }
    
    func snapToPoint(_ point: CGPoint, view: UIView) {
        let snap = UISnapBehavior(item: view, snapTo: point)
        animator?.addBehavior(snap);
    }
    
    // maybe wait until animation finishes to dismiss view
    
    @IBAction func dismissCongratulations(_ sender: AnyObject) {
        gravity.addItem(congratulationsView);
        gravity.gravityDirection = CGVector(dx: 0, dy: 0.8)
        animator = UIDynamicAnimator(referenceView:self.view);
        animator?.addBehavior(gravity)
        self.dismiss(animated: true, completion: {[unowned self] in
            if self.type == AlertType.finish {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.resetApplication()
            }
            // what does this do?
            if let code = self.completion {
                code(sender.titleLabel?.text)
            }
        })
    }
    
    func dismissView() {
        gravity.addItem(congratulationsView);
        gravity.gravityDirection = CGVector(dx: 0, dy: 0.8)
        animator = UIDynamicAnimator(referenceView:self.view);
        animator?.addBehavior(gravity)
        self.dismiss(animated: true, completion: {[unowned self] in
            if self.type == AlertType.finish {
                let delegate = UIApplication.shared.delegate as! AppDelegate
                delegate.resetApplication()
            }
        })
    }
    
    @IBAction func secondaryAction(_ sender: Any) {
        shareApp()
        // needs to hide view after
    }
    // share function again
    func shareApp() {
        let textToShare = "I challenge you to solve this puzzle! Use all four numbers and any operation to make 24."
        
        if let myWebsite = URL(string: "http://www.codingexplorer.com/") {
            let objectsToShare = [textToShare, myWebsite] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            //New Excluded Activities Code
            activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
            
            // TODO: for ipad
            // activityVC.popoverPresentationController?.sourceView = sender as! UIView
            self.present(activityVC, animated: true, completion: nil)
        }
        
    }
    
}
