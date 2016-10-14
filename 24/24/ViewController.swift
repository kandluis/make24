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
import TKSwarmAlert
import SwiftyWalkthrough

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
    // Storyboard
    
    
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
    var playerLevel: Int = 1
    
    // user related variables
    var silent: Bool = false {
        didSet {
            syncMusic()
            
        }
    }
    var player: AVAudioPlayer? = nil
    var backgroundMusicPlayer = AVAudioPlayer()
    
    let pop = NSBundle.mainBundle().URLForResource("pop", withExtension: "mp3")!
    let glassPing = NSBundle.mainBundle().URLForResource("calculated", withExtension: "mp3")!
    let computerMistake = NSBundle.mainBundle().URLForResource("computer_error", withExtension: "mp3")!
    let congrats = NSBundle.mainBundle().URLForResource("congrats", withExtension: "mp3")!
    let ambientSound = NSBundle.mainBundle().URLForResource("background_music", withExtension: "mp3")!
    let fail = NSBundle.mainBundle().URLForResource("fail1", withExtension: "mp3")!
    
    // user defaults
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // seconds to wait
    let triggerTime = Int64(500000000)
    let triggerTime2 = Int64(1000000000)
    
    // Current problem from db
    var selectedProblem: NSManagedObject?
    
    
    // walkthrough
    @IBOutlet weak var skipWalkthroughButton: UIButton!
    @IBOutlet weak var finishedWalkthroughButton: UIButton!
    @IBOutlet weak var walkthroughInstructionsView: UIView!
    var currentHoles = [UIView]()

    /*********
     * View Class Functions
     *********/
    override func viewDidLoad() {
        super.viewDidLoad()
    
        numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        initializeNumbers()
        playBackgroundMusic(ambientSound)
        
        loadSettings()
        
        setAnswerTouchTargets()
        // let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        // if !delegate.hasAppLaunchedBefore(){
        tutorial()
        // }
    
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadSettings(){
        // Sound
        silent = defaults.boolForKey("silent")
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
    func getDifficultyRange(level: Int) -> (Double, Double) {
        let max = Double(level) / 10.0
        return (max - 1 / 10, max)
    }
    
    func loadProblems(level: Int) -> [NSManagedObject] {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Problem")
        
        // Filter to only include levels not completed
        let (minDifficulty, maxDifficulty) = getDifficultyRange(level)
        fetchRequest.predicate = NSPredicate(format: "completed == %@ AND difficulty > %f AND difficulty < %f", false, minDifficulty, maxDifficulty)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "difficulty", ascending: true)]
        
        var results: [AnyObject]?
        do {
            results =
                try managedContext.executeFetchRequest(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return results as? [NSManagedObject] ?? []

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
    
    func syncMusic(){
        if silent == true {
            backgroundMusicPlayer.stop()
            backgroundMusicPlayer.currentTime = 0
        }
        else {
            backgroundMusicPlayer.numberOfLoops = -1
            backgroundMusicPlayer.prepareToPlay()
            backgroundMusicPlayer.play()
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
    func randomProblem() -> [Int]{
        var result = [Int]()
        // initalize numbers to random between 1 and 9
        for _ in 0..<numberButtons.count {
            let randomNumber = Int(arc4random_uniform(9) + 1)
            result.append(randomNumber)
        }
        return result
    }
    
    // From a suitable array of problems, select the one to present.
    func selectProblem(problems: [NSManagedObject]) -> NSManagedObject? {
        print("Selecting from \(problems.count) problems!")
        if problems.count > 0 {
            selectedProblem = problems[Int(arc4random_uniform(UInt32(problems.count)))]
            return selectedProblem
        }
        return nil
    }

    func initializeNumbers() {
        
        clearAnswers()
        let problem = (selectProblem(loadProblems(playerLevel))?.valueForKey("numbers") as! [Int]?) ?? randomProblem()
        
        for index in 0..<numberButtons.count {
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
        
        // if there's a walkthrough /tutorial
        if ongoingWalkthrough {
            removeHoles()
            
            // Answer hole
            addHole(holeToAdd: numberButtons[Int(answerNumber2Label.tag)])
            if numbersLeft == 1 {
                // Walkthrough Ended
                dismissWalkthrough()
                
                initializeNumbers()
            }
            else if numbersLeft == 2 {
                addHole(holeToAdd: numberButtons[3])
                addHole(holeToAdd: multiplyButton)
            }
            else if numbersLeft == 3 {
                addHole(holeToAdd: numberButtons[0])
                addHole(holeToAdd: multiplyButton)
            }
            else {
                // Do nothing
            }
            print(numbersLeft)
        }
        else {
            // check to see if we won
            if numbersLeft == 1 {
                if answer == 24 {
                    didWin()
                }
                else {
                    didLose()
                }
            }
            else {
                // only play sound if not win or lose
                playSound(glassPing)
            }
        }
    }
    
    // We can only ever tap the first answer!
    func tapAnswer(label: UILabel) {
        if label.text != " " {
            setNumberButton(label.tag, text: label.text!)
            label.text = " "
            playSound(pop)
            answersFilled -= 1
            
            if ongoingWalkthrough {
                removeHole(label)
                addHole(holeToAdd: numberButtons[label.tag])
            }
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
            
            if ongoingWalkthrough {
                removeHole(answerOperationLabel)
                addHole(holeToAdd: multiplyButton)
            }
        }
    }
    
    func didWin() {
        selectedProblem?.setValue(true, forKey: "completed")
        
        // Sync core data
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        do {
            try appDelegate.managedObjectContext.save()
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
        congratulations()
    }
    func congratulations() {
        startStopBackgroundMusic()
        playSound(congrats)
        
        defaults.setObject("congratulations", forKey: "alert")
        // old alert
//        let alert = UIAlertController(title: "Congratulations!", message: "You won!! Yays!! ", preferredStyle: UIAlertControllerStyle.Alert)
//        alert.addAction(UIAlertAction(title: "Play Again", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
//        self.presentViewController(alert, animated: true, completion: nil)
        
        scoreLabel.text = String(Int(scoreLabel.text!)! + 1)
        let score = Int(scoreLabel.text!)!
        print("score on View controller: \(score)")
        defaults.setInteger(score, forKey: "score")
        initializeNumbers()
    
        // new alert 
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let myAlert = storyboard.instantiateViewControllerWithIdentifier("alert")
        myAlert.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.presentViewController(myAlert, animated: true, completion: nil)
    }
    
    func didLose() {
        fails()
    }
    func fails() {
        startStopBackgroundMusic()
        playSound(fail)

        // new alert
        defaults.setObject("lost", forKey: "alert")
        
        // new alert
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let myAlert = storyboard.instantiateViewControllerWithIdentifier("alert")
        myAlert.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        self.presentViewController(myAlert, animated: true, completion: nil)
        
//        let alert = UIAlertController(title: "You Failed", message: "Sorry kid!", preferredStyle: UIAlertControllerStyle.Alert)
//        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
//        self.presentViewController(alert, animated: true, completion: nil)
        
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
    @IBAction func populateAnswers(sender: AnyObject) {
        
        // all else
        if answerNumber1Label.text == " " || answerNumber2Label.text == " " {
            let openLabel = answerNumber1Label.text == " " ? answerNumber1Label : answerNumber2Label
            openLabel.text = sender.currentTitle!
            openLabel.tag = sender.tag
            
            // for the walkthrough
            if ongoingWalkthrough {
                removeHole(numberButtons[sender.tag])
                addHole(holeToAdd: openLabel)
            }
            
            if answersFilled < 3 {
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
            answersFilled = answersFilled + 1
        }
        
        //play pop sound
        playSound(pop)
        answerOperationLabel.text = sender.currentTitle!
        if ongoingWalkthrough {
            addHole(holeToAdd: answerOperationLabel)
            if let operation = sender as? UIView {
                removeHole(operation)
            }
        }
        
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
    
    @IBAction func saveScore(sender: AnyObject) {
        let gameScore = Int(scoreLabel.text!)!
        saveHighscore(gameScore)
    }
    
    func showLeaderboard() {
        // authenticate player to enable game center
        authenticateLocalPlayer()
        // show leaderboard
        let viewControllerVar = self.view?.window?.rootViewController
        let gKGCViewController = GKGameCenterViewController()
        gKGCViewController.gameCenterDelegate = self
        viewControllerVar?.presentViewController(gKGCViewController, animated: true, completion: nil)
        
    }
    @IBAction func showLeader(sender: AnyObject) {
        showLeaderboard()
        
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
    
    /* GKGameCenterlDelgate Function */
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func authenticateLocalPlayer() {
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {(viewController, error) -> Void in
            
            if (viewController != nil) {
                self.presentViewController(viewController!, animated: true, completion: nil)
            }

        }
    }
    
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
    
    
    // this should probably be in a separate file - thoughts?
    // code for the new alert options
    
    func createOptionsView(viewTapped: UITapGestureRecognizer,  image_name: String, text: String, frame: CGRect)  ->  SampleDesignView{

        
        let newView = SampleDesignView(type: SampleDesignViewType.Bar(icon:UIImage(named: image_name), text:text), frame: frame)
        
        print("type")
        print(self.tapDetected())
        
        viewTapped.numberOfTapsRequired = 1
        newView.userInteractionEnabled = true
        newView.addGestureRecognizer(viewTapped)
        
        return newView
        
    }
    
    /*********
     * Options Menu Functions
     *********/
    
    func makeSampleViews1()->[UIView] {
        let height:CGFloat = 64
        let width:CGFloat = 300
        let margin:CGFloat = 10
        let x:CGFloat = self.view.frame.width / 2 - width/2
        let y:CGFloat = 160//240
        let f1 = CGRectMake(x, y, width, height)
        let f2 = CGRectMake(x, y + (height + margin), width, height)
        let f3 = CGRectMake(x, y + (height + margin) * 2, width, height)
        let f4 = CGRectMake(x, y + (height + margin) * 3, width, height)
        let f5 = CGRectMake(x, y + (height + margin) * 4, width, height)
        
        var views:[UIView] = []
        
        // leadership option
        var viewTapped = UITapGestureRecognizer(target: self, action:#selector(self.showLeaderboard))
        let leaderboardView = createOptionsView(viewTapped, image_name: "leaderboard_colored", text: "Leaderboard", frame: f1)
        views.append(leaderboardView)
        
        // more games option
        viewTapped = UITapGestureRecognizer(target: self, action:#selector(self.tapDetected))
        let gameView = createOptionsView(viewTapped, image_name: "games_colored", text: "More games", frame: f2)
        views.append(gameView)
        
        // tutorial option
        
        let newView = SampleDesignView(type: SampleDesignViewType.Bar(icon:UIImage(named: "tutorial_colored"), text:"Tutorial"), frame: f3)
        
        print("type")
        print(self.tapDetected())
        
        
//        viewTapped = UITapGestureRecognizer(target: self, action:#selector(self.tutorial))
//        let tutorialView = createOptionsView(viewTapped, image_name: "tutorial_colored", text: "Tutorial", frame: f3)
        views.append(newView)
        
        // rate option
        viewTapped = UITapGestureRecognizer(target: self, action:#selector(self.tapDetected))
        let rateView = createOptionsView(viewTapped, image_name: "star_colored", text: "Rate the app", frame: f4)
        views.append(rateView)
        
        // share option
        viewTapped = UITapGestureRecognizer(target: self, action:#selector(self.tapDetected))
        let shareView = createOptionsView(viewTapped, image_name: "share_colored", text: "Share with friends", frame: f5
        )
        views.append(shareView)
        
        return views
    }
    
    func tapDetected() {
        alert.hide()
    }

    let alert = TKSwarmAlert()
    
    @IBAction func showOptions(sender: AnyObject) {
        let views = makeSampleViews1()
        alert.show(type: .TransparentBlack(alpha: 0.70), views: views)
    }
    
    /*********
     * Tutorial Walkthrough
     *********/
    
    var customWalkthroughView: CustomWalkthroughView? { return walkthroughView as? CustomWalkthroughView }
    
    func tutorial() {
        
        // Turn off music
        silent = true
        
        clearAnswers()
        
        // initial set
        setNumberButton(0, text: "1")
        setNumberButton(1, text: "3")
        setNumberButton(2, text: "8")
        setNumberButton(3, text: "1")
        
        // Numbers used reset!
        numbersLeft = 4
    
        startWalkthrough(CustomWalkthroughView())
        createHoles(holesToCreate: [walkthroughInstructionsView, number2Button, number3Button, multiplyButton])
        
    }
    
    func createHoles(holesToCreate holes: [UIView]){
        let descriptors = holes.map({element in ViewDescriptor(view:element, cornerRadius: 10)})
        walkthroughView?.cutHolesForViewDescriptors(descriptors)
        
        // Update hole history
        currentHoles = holes
    }
    
    func removeHoles(){
        walkthroughView?.removeAllHoles()
        currentHoles = []
        
        // always add the walkthrough instructions
        if ongoingWalkthrough {
            addHole(holeToAdd: walkthroughInstructionsView)
        }
    }
    
    func addHole(holeToAdd hole: UIView){
        currentHoles.append(hole)
        createHoles(holesToCreate: currentHoles)
    }
    
    func removeHole(element: UIView){
        var holes = currentHoles
        if let index = currentHoles.indexOf(element) {
            holes.removeAtIndex(index)
            walkthroughView?.removeAllHoles()
            createHoles(holesToCreate: holes)
        }
    }
    
    func dismissWalkthrough(){
        walkthroughInstructionsView.hidden = true
        finishWalkthrough()
        loadSettings()
    }
    
    @IBAction func dismissWalkthrough(sender: AnyObject) {
        dismissWalkthrough()
        
    }
}

