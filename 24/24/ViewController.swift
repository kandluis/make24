//
//  ViewController.swift
//  24
//
//  Created by Luis Perez on 10/5/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData
import GameplayKit
import GameKit

extension Double {
    private typealias Rational = (num: Int, den: Int)
    
    /*!
     * @brief The numberator when interpreted as a reduced fraction.
     */
    var num: Int {
        return rationalApproximationOf(self).num
    }
    /*! 
     * @brief The denominator when interpreted as a reduced fraction.
     */
    var den: Int {
        return rationalApproximationOf(self).den
    }

    /*!
     * @discussion Custom initializer from fraction strings. Delages to default.
     * @param from A string representation of the desired double.
     * @return The parsed double.
     */
    init?(from text: String) {
        self.init(text)
        let comps = text.componentsSeparatedByString("/")
        if comps.count == 2 {
            // A fraction, convert to double ourselves
            let num = Double(comps[0])!
            let den = Double(comps[1])!

            self = num / den
        }
    }
    
    /*!
     * @discussion Improved string conversion method for Doubles supporting fractions.
     * @return A string representation of the doubles value
     */
    func toString() -> String {
        if self.den == 1 {
            return String(self.num)
        }
        return String(format:"%d/%d", self.num, self.den)
    }
    
    // LCM for Double using continued fraction approximation for fast convergence.
    // For more about this method, see: https://en.wikipedia.org/wiki/Continued_fraction
    // For code see: http://stackoverflow.com/questions/28349864/algorithm-for-lcm-of-doubles-in-swift/28352004#28352004
    private func rationalApproximationOf(x0: Double, withPrecision eps: Double = 1.0E-6) -> Rational {
        var x: Double = x0
        var a: Double = floor(x)
        var (h1, k1, h, k): (Int, Int, Int, Int) = (1, 0, Int(a), 1)
        
        while x - a > eps * Double(k) * Double(k) {
            x = 1.0/(x - a)
            a = floor(x)
            (h1, k1, h, k) = (h, k, h1 + Int(a) * h, k1 + Int(a) * k)
        }
        return (h, k)
    }
}

class ViewController: UIViewController, GKGameCenterControllerDelegate {
    
    // Answer board area.
    @IBOutlet weak var answerNumber1Label: UILabel!
    @IBOutlet weak var answerOperationLabel: UILabel!
    @IBOutlet weak var answerNumber2Label: UILabel!
    
    // Operations below answer board
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var newSetButton: UIButton!
    
    // Player buttons
    @IBOutlet weak var number1Button: UIButton!
    @IBOutlet weak var number2Button: UIButton!
    @IBOutlet weak var number3Button: UIButton!
    @IBOutlet weak var number4Button: UIButton!
    var numberButtons = [UIButton!]()
    
    // Player operations
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var multiplyButton: UIButton!
    @IBOutlet weak var divideButton: UIButton!
    
    // Game options
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var soundIcon: UIImageView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var saveScoreButton: UIButton!
    
    // Gameplay related variables
    var answersFilled: Int = 0
    var numbersLeft: Int = 4
    var currentNumbers = [Int:Int]()
    var playerLevel: Int = 0
    
    // sound related variables
    var silent: Bool = false
    var player: AVAudioPlayer? = nil
    var backgroundMusicPlayer = AVAudioPlayer()
    
    let pop = NSBundle.mainBundle().URLForResource("pop", withExtension: "mp3")!
    let glassPing = NSBundle.mainBundle().URLForResource("calculated", withExtension: "mp3")!
    let computerMistake = NSBundle.mainBundle().URLForResource("computer_error", withExtension: "mp3")!
    let congrats = NSBundle.mainBundle().URLForResource("congrats", withExtension: "mp3")!
    let ambientSound = NSBundle.mainBundle().URLForResource("background_music", withExtension: "mp3")!
    let fail = NSBundle.mainBundle().URLForResource("fail1", withExtension: "mp3")!
    
    // seconds to wait
    let triggerTime = Int64(500000000)
    let triggerTime2 = Int64(1000000000)
    // Persistent storage variables
    var problems = [NSManagedObject]()

    /*********
     * View Class Functions
     *********/
    override func viewDidLoad() {
        super.viewDidLoad()
    
        numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        loadProblems()
        initializeNumbers()
        playBackgroundMusic(ambientSound)
        
        // make sure the mute button has text left aligned
        muteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        
        setAnswerTouchTargets()
        
        // authenticate player to enable game center
        authenticateLocalPlayer()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*****
     * Touch Targets
     ******/
    func setAnswerTouchTargets(){
        answerNumber1Label.userInteractionEnabled = true
        answerNumber1Label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapAnswer1)))
        answerOperationLabel.userInteractionEnabled = true
        answerOperationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapOperation)))
        answerNumber2Label.userInteractionEnabled = true
        answerNumber2Label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapAnswer2)))
    }
    
    /************
     * Database Functions
     *************/
    func loadProblems(){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Problem")
        
        do {
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            problems = results as! [NSManagedObject]
            print(problems.count)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }

    }
    
    /*****************
     * Sound Functions
     *****************/
    func playSound(sound: NSURL) {
        if silent == false {
            do {
                player = try AVAudioPlayer(contentsOfURL: sound)
                guard let player = player else { return }
                
                player.prepareToPlay()
                player.play()
            } catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    func playBackgroundMusic(sound: NSURL) {
        if silent == false {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOfURL: ambientSound)
                
                backgroundMusicPlayer.numberOfLoops = -1
                backgroundMusicPlayer.prepareToPlay()
                backgroundMusicPlayer.play()
                
            } catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    func startStopBackgroundMusic() {
        if silent == true {
            backgroundMusicPlayer.stop()
            backgroundMusicPlayer.currentTime = 0
        }
        else {
            if backgroundMusicPlayer.playing {
                backgroundMusicPlayer.stop()
                backgroundMusicPlayer.currentTime = 0
            }
            else {
                backgroundMusicPlayer.numberOfLoops = -1
                backgroundMusicPlayer.prepareToPlay()
                backgroundMusicPlayer.play()
            }
        }
    }
    
    /*******
     * Gameplay Functions
     *******/
    // From database, retrieve all problems suitable for this level.
    func retrieveSuitableProblems(level: Int) -> [[Int]] {
        var result = [1, 2, 3, 4]
        // initalize numbers to random between 1 and 9
        for index in numberButtons.indices {
            let randomNumber = Int(arc4random_uniform(9) + 1)
            result[index] = randomNumber
        }
        return [result]
    }
    
    // From a suitable array of problems, select the one to present.
    func selectProblem(problems: [[Int]]) -> [Int] {
        if problems.count > 0 {
            let problem = problems[Int(arc4random_uniform(UInt32(problems.count)))]
            let shuffled = GKRandomSource.sharedRandom().arrayByShufflingObjectsInArray(problem)
            return shuffled as! [Int]
        }
        var result = [1, 2, 3, 4]
        // initalize numbers to random between 1 and 9
        for index in numberButtons.indices {
            let randomNumber = Int(arc4random_uniform(9) + 1)
            result[index] = randomNumber
        }
        return result
    }
    
    func initializeNumbers() {
        
        clearAnswers()
        let problems: [[Int]] = retrieveSuitableProblems(playerLevel)
        let problem: [Int] = selectProblem(problems)
        for index in numberButtons.indices {
            let selectedNumber = problem[index]
            setNumberButton(index, text: String(problem[index]))
            currentNumbers[index] = selectedNumber
        }

        // Numbers used reset!
        numbersLeft = 4
    }
    
    func computeAnswer() {
        guard let op = answerOperationLabel?.text else { return }
        guard let number1 = Double(from: answerNumber1Label.text!) else { return }
        guard let number2 = Double(from: answerNumber2Label.text!) else { return }
        var answer: Double = 0
        
        switch op {
        case "+" :
            answer = number1 + number2
        case "-" :
            answer = number1 - number2
        case "x" :
            answer = number1 * number2
        case "/" :
            if number2 == 0 {
                startStopBackgroundMusic()
                
                let alert = UIAlertController(title: "Invalid Operation", message: "Division by zero is not allowed! ", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
                self.presentViewController(alert, animated: true, completion: nil)
                playSound(computerMistake)
                return clearBoard()
            }
            answer = number1 / number2
        default:
            return
        }
        
            
        setNumberButton(answerNumber2Label.tag, text: answer.toString())
        clearAnswers()
        
        // decrement numbers left
        numbersLeft = numbersLeft - 1
        
        // check to see if we won
        if numbersLeft == 1 {
            if answer == 24 {
                congratulations()
            }
            else {
                fails()
            }
        }
        else {
            // only play sound if not win or lose
            playSound(glassPing)
        }
    }
    
    // We can only ever tap the first answer!
    func tapAnswer(label: UILabel) {
        if label.text != " " {
            setNumberButton(label.tag, text: label.text!)
            label.text = " "
            playSound(pop)
            answersFilled -= 1
        }
    }
    func tapAnswer1(){
        tapAnswer(answerNumber1Label)
    }
    func tapAnswer2(){
        tapAnswer(answerNumber2Label)
    }
    
    func tapOperation() {
        if answerOperationLabel != " " {
            answerOperationLabel.text = " "
            playSound(pop)
            answersFilled -= 1
        }
    }
    
    func congratulations() {
        startStopBackgroundMusic()
        playSound(congrats)
        let alert = UIAlertController(title: "Congratulations!", message: "You won!! Yays!! ", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Play Again", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
        self.presentViewController(alert, animated: true, completion: nil)
        
        scoreLabel.text = String(Int(scoreLabel.text!)! + 1)
        initializeNumbers()
    }
    
    func fails() {
        startStopBackgroundMusic()
        playSound(fail)
        
        let alert = UIAlertController(title: "You Failed", message: "Sorry kid!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
        self.presentViewController(alert, animated: true, completion: nil)
        
        reset()
    }
    
    /*********
     * Graphical Functions
     **********/
    func clearAnswers(){
        answerNumber1Label.text = " "
        answerNumber2Label.text = " "
        answerOperationLabel.text = " "
        
        answersFilled = 0
    }
    
    func setNumberButton(index: Int, text: String) {
        numberButtons[index].setTitle(text, forState: .Normal)
        numberButtons[index].setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
    }
    
    func clearNumberButton(index: Int){
        numberButtons[index].setTitle(" ", forState: .Normal)
        // sets number button to blank background color
        numberButtons[index].setBackgroundImage(nil, forState: .Normal)
    }
    
    func clearBoard() {
        // Move selected numbers back to board
        if answerNumber1Label.text != " "{
            setNumberButton(answerNumber1Label.tag, text: answerNumber1Label.text!)
        }
        if answerNumber2Label.text != " "{
            setNumberButton(answerNumber2Label.tag, text: answerNumber2Label.text!)
        }
        clearAnswers()
    }
    
    func reset(){
        numbersLeft = 4
        for button in numberButtons {
            let originalNumber = Int(currentNumbers[button.tag]!)
            button.setTitle(String(originalNumber), forState: .Normal)
            button.setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
        }
        clearAnswers()
    }

    /******
     * User Actions
     ******/
    @IBAction func turnOnOffAudio(sender: AnyObject) {
        if !silent {
            silent = true
            muteButton.setTitle(" UNMUTE", forState: .Normal)
            soundIcon.image = UIImage(named: "mute_white")
        }
        else {
            silent = false
            muteButton.setTitle("    MUTE", forState: .Normal)
            soundIcon.image = UIImage(named: "sound_white")
        }
        startStopBackgroundMusic()
    }
    
    @IBAction func populateAnswers(sender: AnyObject) {
        if answerNumber1Label.text == " " || answerNumber2Label.text == " " {
            let openLabel = answerNumber1Label.text == " " ? answerNumber1Label : answerNumber2Label
            openLabel.text = sender.currentTitle!
            openLabel.tag = sender.tag
            if answersFilled < 3{
                answersFilled = answersFilled + 1;
            }
            playSound(pop)
            clearNumberButton(sender.tag)
        }
        else {
            // Do nothing
            playSound(computerMistake)
        }
        
        if answersFilled == 3 {
            // delay so user can see full answers
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, triggerTime), dispatch_get_main_queue(), { () -> Void in
                self.computeAnswer()
            })
        }
    }
    
    @IBAction func populateOperation(sender: AnyObject) {
        if answerOperationLabel.text == " " && answersFilled < 3 {
            answersFilled = answersFilled + 1;
        }
        
        //play pop sound
        playSound(pop)
        answerOperationLabel.text = sender.currentTitle!;
        
        if answersFilled == 3 {
            // delay so user can see full answers
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, triggerTime), dispatch_get_main_queue(), { () -> Void in
                self.computeAnswer()
            })
        }
    }
    
    @IBAction func resetButton(sender: AnyObject) {
        reset()
    }
    
    @IBAction func clearBoardButton(sender: AnyObject) {
        clearBoard()
    }
    
    @IBAction func newSet(sender: AnyObject) {
        initializeNumbers()
    }
    
    // check on device, if need to explicitly add text, Twitter, FB http://nshipster.com/uiactivityviewcontroller/
    
    // verify on device
    
    func shareApp() {
        print("TEST")
        loadView()
        
        if (self.isViewLoaded()) {
//            viewDidLoad()
//            
//            congratulations()
//            
//            let textToShare = "Swift is awesome!  Check out this website about it!"
//            
//            if let myWebsite = NSURL(string: "http://www.codingexplorer.com/") {
//                let objectsToShare = [textToShare, myWebsite]
//                // could create own custom share function (instead of setting nil)
//                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
//                
//                //New Excluded Activities Code
//                activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
//                
//                // for ipad
//                //            activityVC.popoverPresentationController?.sourceView = sender as! UIView
//                self.presentViewController(activityVC, animated: true, completion: nil)
//            }

        }
        else {
            print("view hasn't loaded")
        }
        
    }
    
    @IBAction func share(sender: AnyObject) {
        let textToShare = "Swift is awesome!  Check out this website about it!"
        
        if let myWebsite = NSURL(string: "http://www.codingexplorer.com/") {
            let objectsToShare = [textToShare, myWebsite]
            // could create own custom share function (instead of setting nil)
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            //New Excluded Activities Code
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            
            // for ipad
            activityVC.popoverPresentationController?.sourceView = sender as? UIView
            self.presentViewController(activityVC, animated: true, completion: nil)
        }

    }
    
    // end share code
    
    // authenticate the player
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            
            if (viewController != nil) {
                self.presentViewController(viewController!, animated: true, completion: nil)
            }

        }
    }
    
    @IBAction func showLeader(sender: AnyObject) {
        let viewControllerVar = self.view?.window?.rootViewController
        let gKGCViewController = GKGameCenterViewController()
        gKGCViewController.gameCenterDelegate = self
        viewControllerVar?.presentViewController(gKGCViewController, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func saveScore(sender: AnyObject) {
        let gameScore = Int(scoreLabel.text!)!
        saveHighscore(gameScore)
    }
    
    //sends the highest score to leaderboard
    func saveHighscore(gameScore: Int) {
        let my_leaderboard_id = "Overall"
        let scoreReporter = GKScore(leaderboardIdentifier: my_leaderboard_id)
        
        scoreReporter.value = Int64(gameScore)
        print("starting score")
        print(scoreReporter.value)
        print("ending score")
        let scoreArray: [GKScore] = [scoreReporter]
        
        GKScore.reportScores(scoreArray, withCompletionHandler: {error -> Void in
            if error != nil {
                print("An error has occured:")
                print("\n \(error) \n")
            }
        })
        
//        if GKLocalPlayer.localPlayer().authenticated {
//            print("Player has actually been.")
//            let scoreReporter = GKScore(leaderboardIdentifier: "Overall")
//            scoreReporter.value = Int64(gameScore)
//            let scoreArray: [GKScore] = [scoreReporter]
//            
//            GKScore.reportScores(scoreArray, withCompletionHandler: {error -> Void in
//                if error != nil {
//                    print("An error has occured: \(error)")
//                }
//            })
//        }
//        else {
//            print(GKLocalPlayer.localPlayer().authenticated)
//        }
    }
    // code for multiplayer mode //

    
    
}

