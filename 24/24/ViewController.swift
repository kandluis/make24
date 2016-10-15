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

let APP_ID = "id959379869"

extension String {
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    }
}

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
        let comps = text.componentsSeparatedByString("/")
        if comps.count == 2 {
            // A fraction, convert to double ourselves
            let num = Double(comps[0])!
            let den = Double(comps[1])!

            self.init(num / den)
        }
        else {
            self.init(text)
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
    var playerLevel: Int = 1 {
        didSet(oldValue) {
            // Safeguards
            if playerLevel >= 1 && playerLevel <= maxLevel {
                defaults.setInteger(playerLevel, forKey: "level")
            }
            else {
                playerLevel = oldValue
            }
        }
    }
    var puzzlesSolved: Int = 0 {
        didSet(oldValue) {
            if puzzlesSolved >= 0 && puzzlesSolved <= puzzlesPerLevel {
                defaults.setInteger(puzzlesSolved, forKey: "puzzles")
            }
            else {
                puzzlesSolved = oldValue
            }
        }
    }
    var playerScore: Int = 0 {
        didSet(oldValue) {
            // Safeguards
            if playerScore >= 0 {
                scoreLabel.text = String(playerScore)
                defaults.setInteger(playerScore, forKey: "score")
            }
            else {
                playerScore = oldValue
            }
        }
    }
    let maxLevel: Int = 10
    let puzzlesPerLevel: Int = 10
    var silent: Bool = false {
        didSet {
            defaults.setBool(silent, forKey: "silent")
            syncMusic()
            
        }
    }
    // Current problem from db
    var selectedProblem: NSManagedObject?
    
    // Audio variables
    var player: AVAudioPlayer? = nil
    var backgroundMusicPlayer = AVAudioPlayer()
    let pop = NSBundle.mainBundle().URLForResource("pop", withExtension: "mp3")!
    let glassPing = NSBundle.mainBundle().URLForResource("calculated", withExtension: "mp3")!
    let computerMistake = NSBundle.mainBundle().URLForResource("computer_error", withExtension: "mp3")!
    let congrats = NSBundle.mainBundle().URLForResource("congrats", withExtension: "mp3")!
    let ambientSound = NSBundle.mainBundle().URLForResource("background_music", withExtension: "mp3")!
    let fail = NSBundle.mainBundle().URLForResource("fail1", withExtension: "mp3")!
    
    // User defaults
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // Seconds to wait on  transitions.
    let TRIGGERTIME = Int64(500000000)
    
    // Views
    let optionsView = TKSwarmAlert()

    // Walthrough
    @IBOutlet weak var skipWalkthroughButton: UIButton!
    @IBOutlet weak var walkthroughInstructionsView: UIView!
    var currentHoles = [UIView]()
    
    // Leaderboard
    var localPlayer: GKLocalPlayer?
    let LEADER_BOARD_ID = "Overall"

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
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if !delegate.hasAppLaunchedBefore(){
            tutorial()
        }
    
    
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
    
    /******
     * Settings Functions
     ******/
    func loadSettings(){
        // Sound
        silent = defaults.boolForKey("silent")
        playerLevel = defaults.integerForKey("level")
        playerScore = defaults.integerForKey("score")
        puzzlesSolved = defaults.integerForKey("puzzles")
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
    // We can only ever tap the first answer!
    func tapAnswer(label: UILabel) {
        if let text = label.text {
            if text.trim() != "" {
                setNumberButton(label.tag, text: text)
                label.text = " "
                playSound(pop)
                answersFilled -= 1
                
                if ongoingWalkthrough {
                    removeHole(label)
                    addHole(holeToAdd: numberButtons[label.tag])
                }
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
        if let text = answerOperationLabel.text {
            if text.trim() != "" {
                answerOperationLabel.text = " "
                playSound(pop)
                answersFilled -= 1
                
                if ongoingWalkthrough {
                    removeHole(answerOperationLabel)
                    addHole(holeToAdd: multiplyButton)
                }
            }
        }
    }
    
    /************
     * Database Functions
     *************/
    func getDifficultyRange(level: Int) -> (Double, Double) {
        let maxLevel = Double(self.maxLevel)
        let level = Double(self.playerLevel)
        let max = level / maxLevel
        return (max - 1 / maxLevel, max)
    }
    
    func loadProblems(level: Int) -> [NSManagedObject] {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return []
        }
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
        if !silent {
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
        if !silent {
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
        if silent {
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
        if silent {
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
    func randomProblem() -> [Int] {
        print("Selecting a random problem. This is not guaranteed to be solvable")
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
        var selectedProblem: NSManagedObject?
        if problems.count > 0 {
            selectedProblem = problems[Int(arc4random_uniform(UInt32(problems.count)))]
        }
        return selectedProblem
    }

    func initializeNumbers() {
        
        clearAnswers()
        if let problem = (selectProblem(loadProblems(playerLevel))?.valueForKey("numbers") as? [Int]) {
            
            for index in 0..<numberButtons.count {
                let selectedNumber = problem[index]
                setNumberButton(index, text: String(problem[index]))
                currentNumbers[index] = selectedNumber
            }

            // Numbers used reset!
            numbersLeft = 4
        }
        else {
            let alert = UIAlertController(title: "Out of problems!", message: "You've run out of problems! Sending you back to square 1!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
            self.presentViewController(alert, animated: true, completion: nil)
            
            let delegate = UIApplication.sharedApplication().delegate as!AppDelegate
            delegate.resetApplication()
            initializeNumbers()
        }
    }
    
    // Operations to perform after an answer has been calcuated successfully.
    func calculatedAnswer(answer: Double){
        clearAnswers()
        
        // decrement numbers left
        numbersLeft = numbersLeft - 1
        
        // if there's a walkthrough /tutorial
        if ongoingWalkthrough {
            removeHoles()
            
            // Answer hole
            addHole(holeToAdd: numberButtons[Int(answerNumber2Label.tag)])
            if numbersLeft ==   1 {
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
    
    func computeAnswer(){
        guard let op = answerOperationLabel?.text else { return }
        guard let number1 = Double(from: answerNumber1Label.text ?? "") else { return }
        guard let number2 = Double(from: answerNumber2Label.text ?? "") else { return }
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
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
                self.presentViewController(alert, animated: true, completion: nil)
                playSound(computerMistake)
                return clearBoard()
            }
            answer = number1 / number2
        default:
            return
        }
        
        // Set the answer
        setNumberButton(answerNumber2Label.tag, text: answer.toString())
        calculatedAnswer(answer)
        
    }
    
    /***********
     * Gameplay Display Functions
     ***********/
    // Function is called before any variables are updated on a win
    func getAlertTypeOnWin() -> String {
        if puzzlesSolved == puzzlesPerLevel - 1 {
            if playerLevel == maxLevel {
                return "finish"
            }
            return "next_level"
        }
        return "next_puzzle"
    }
    func didWin() {
        // Core data is synchronized when the application exits!
        selectedProblem?.setValue(true, forKey: "completed")
        congratulations()
    }
    func congratulations() {
        startStopBackgroundMusic()
        playSound(congrats)
        
        // Start a new game!
        initializeNumbers()
    
        // Determine type of alert!
        print(getAlertTypeOnWin())
        presentAlert(getAlertTypeOnWin())
        
        // Update player info
        puzzlesSolved += 1
        playerScore += playerLevel
        // Check if level is passed
        if puzzlesSolved == puzzlesPerLevel {
            playerLevel += 1
            puzzlesSolved = 0
        }
    }
    
    func didLose() {
        fails()
    }
    func fails() {
        startStopBackgroundMusic()
        playSound(fail)
        
        presentAlert("fail")
        reset()
    }
    func presentAlert(alert_type: String){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let myAlert = storyboard.instantiateViewControllerWithIdentifier("alert") as? CongratulationsViewController {
            myAlert.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            myAlert.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            myAlert.setOptions(alertStringIdentifier: alert_type, currentLevel: playerLevel, puzzlesSolved: puzzlesSolved + 1, completion: {[unowned self](buttonText: String?) -> Void in
                if let text = buttonText {
                    if text == "Leaderboard" {
                        self.showLeaderboard()
                    }
                }
                self.startStopBackgroundMusic()
                })
            self.presentViewController(myAlert, animated: true, completion: nil)
        }
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
        if let text = answerNumber1Label.text {
            if text.trim() != "" {
                setNumberButton(answerNumber1Label.tag, text: text)
            }
        }
        if let text = answerNumber2Label.text {
            if text.trim() != "" {
                setNumberButton(answerNumber2Label.tag, text: text)
            }
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

    /************
     * Leaderboard Functions
     ************/
    func showLeaderboard() {
        let show = {[unowned self] in
            self.reportIfHigher(self.playerScore, afterReport: { [unowned self] in
                self.showLeaderboardView()
                })
        }
        if let authenticated = localPlayer?.authenticated {
            if authenticated {
                show()
            }
            else {
                // Player dismissed authentication, alert that they
                // must login through GameCenter
                let title = "Cannot login!"
                let message = "Login through the Game Center App to access this feature!"
                let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default) { _ in })
                self.presentViewController(alert, animated: true, completion: {})
            }
        }
        else {
            authenticateLocalPlayer(onAuthetication: show)
        }
    }
    func authenticateLocalPlayer(onAuthetication completion: Closure) {
        localPlayer = GKLocalPlayer.localPlayer()
        localPlayer?.authenticateHandler = {(viewController, error) -> Void in
            
            if (viewController != nil) {
                self.presentViewController(viewController!, animated: true, completion: completion)
            }
        }
        
    }
    // Player must be authenticated.
    func reportIfHigher(gameScore: Int, afterReport completion: Closure) {
        if let authenticated = localPlayer?.authenticated {
            if authenticated {
                let leaderboardRequest = GKLeaderboard()
                leaderboardRequest.identifier = LEADER_BOARD_ID
                leaderboardRequest.loadScoresWithCompletionHandler({[unowned self](scores, error) -> Void in
                    if let remoteScore = leaderboardRequest.localPlayerScore?.value {
                        if Int(remoteScore) < gameScore {
                            self.reportScore(gameScore)
                        }
                    }
                    })

            }
            else {
                completion()
            }
        }
    }
    // Player must be authenticated
    func reportScore(score: Int) {
        if let authenticated = localPlayer?.authenticated {
            if authenticated {
                let scoreReporter = GKScore(leaderboardIdentifier:LEADER_BOARD_ID)
                
                scoreReporter.value = Int64(score)
                let scoreArray: [GKScore] = [scoreReporter]
                GKScore.reportScores(scoreArray, withCompletionHandler: {error -> Void in
                    if error != nil {
                        print("An error has occured:")
                        print("\n \(error) \n")
                    }
                })
            }
        }
    }
    // Player must be authenticated
    func showLeaderboardView() {
        if let authenticated = localPlayer?.authenticated {
            if authenticated {
                let viewControllerVar = self.view?.window?.rootViewController
                let gKGCViewController = GKGameCenterViewController()
                gKGCViewController.gameCenterDelegate = self
                viewControllerVar?.presentViewController(gKGCViewController, animated: true, completion: nil)
            }
        }
    }
    
    /* GKGameCenterlDelgate Function */
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /*********
     * Tutorial Walkthrough
     *********/
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
        
        // make sure to unhide walkthrough
        startWalkthrough(WalkthroughView())
        walkthroughInstructionsView.hidden = false
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
        initializeNumbers()
    }
    
    /*********
     * Options Menu Functions
     *********/
    func createOptionsView(viewTapped: UITapGestureRecognizer,  image_name: String, text: String, frame: CGRect)  ->  SampleDesignView{
        
        
        let newView = SampleDesignView(type: SampleDesignViewType.Bar(icon:UIImage(named: image_name), text:text), frame: frame)
        
        viewTapped.numberOfTapsRequired = 1
        newView.userInteractionEnabled = true
        newView.addGestureRecognizer(viewTapped)
        
        return newView
        
    }
    typealias ViewInfo = (selector: Selector, image: String, text: String)
    func makeOptionsViews(viewInfo: [ViewInfo])->[UIView] {
        let height:CGFloat = 54
        let width:CGFloat = 300
        let margin:CGFloat = 10
        let x:CGFloat = self.view.frame.width / 2 - width/2
        let y:CGFloat = 160//240
        
        return viewInfo.enumerate().map({(i, info) -> UIView in
            let rect = CGRectMake(x, y + (height + margin) * CGFloat(i), width, height)
            let tap = UITapGestureRecognizer(target: self, action: info.selector)
            let view = createOptionsView(tap, image_name: info.image, text: info.text, frame: rect)
            return view

        })
    }
    func leaderBoardOption() {
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.showLeaderboard()
        }
        self.optionsView.hide()
    }
    func moreGamesOption() {
        // TODO: Implement ads
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
        }
        self.optionsView.hide()
    }
    func tutorialOption() {
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.tutorial()
        }
        self.optionsView.hide()
    }
    func rateOption() {
        // TODO: Test rating!
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            let url_string = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(APP_ID)"
            if let url = NSURL(string: url_string) {
                UIApplication.sharedApplication().openURL(url)
            }
        }
        self.optionsView.hide()
    }
    func shareOption(){
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.shareApp()
        }
        self.optionsView.hide()
    }
    func soundToggle(){
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.silent = !self.silent
        }
        self.optionsView.hide()
    }
    
    /***********
     * Share Options
     ***********/
    func shareApp() {
        let textToShare = "I'm playing this new, awesome game! Check it out!"
        
        if let myWebsite = NSURL(string: "http://www.codingexplorer.com/") {
            let objectsToShare = [textToShare, myWebsite]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            //New Excluded Activities Code
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop, UIActivityTypeAddToReadingList]
            
            // TODO: for ipad
            // activityVC.popoverPresentationController?.sourceView = sender as! UIView
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    
    }
    
    /******
     * User Actions
     ******/
    @IBAction func populateAnswers(sender: AnyObject) {
        
        // all else
        guard let text1 = answerNumber1Label.text else { return }
        guard let text2 = answerNumber2Label.text else { return }
        if text1.trim() == "" || text2.trim() == "" {
            let openLabel = text1.trim() == "" ? answerNumber1Label : answerNumber2Label
            openLabel.text = (sender as? UIButton)?.currentTitle ?? ""
            openLabel.tag = ((sender as? UIButton)?.tag)!
            
            // for the walkthrough
            if ongoingWalkthrough {
                removeHole(numberButtons[openLabel.tag])
                addHole(holeToAdd: openLabel)
            }
            
            if answersFilled < 3 {
                answersFilled = answersFilled + 1;
            }
            
            playSound(pop)
            clearNumberButton(openLabel.tag)
        }
        else {
            // Do nothing
            playSound(computerMistake)
        }
        
        if answersFilled == 3 {
            // delay so user can see full answers
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, TRIGGERTIME), dispatch_get_main_queue(), { () -> Void in
                self.computeAnswer()
            })
        }
    }
    
    @IBAction func populateOperation(sender: AnyObject) {
        guard let text = answerOperationLabel.text else { return }
        if text.trim() == "" && answersFilled < 3 {
            answersFilled = answersFilled + 1
        }
        
        //play pop sound
        playSound(pop)
        answerOperationLabel.text = (sender as? UIButton)?.currentTitle ?? ""
        if ongoingWalkthrough {
            addHole(holeToAdd: answerOperationLabel)
            if let operation = sender as? UIView {
                removeHole(operation)
            }
        }
        
        if answersFilled == 3 {
            // delay so user can see full answers
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, TRIGGERTIME), dispatch_get_main_queue(), { () -> Void in
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
    
    @IBAction func showLeader(sender: AnyObject) {
        showLeaderboard()
        
    }
    @IBAction func showOptions(sender: AnyObject) {
        let muteButtonText = silent ? "Unmute" : "Mute"
        let soundIcon = silent ? "mute_grey" : "sound_grey"
        let info = [
            (selector: #selector(self.leaderBoardOption), image: "leaderboard_colored", text: "Leaderboard"),
            (selector: #selector(self.soundToggle), image: soundIcon, text: muteButtonText),
            (selector: #selector(self.tutorialOption), image: "tutorial_colored", text: "Tutorial"),
            (selector: #selector(self.rateOption), image: "star_colored", text: "Rate the app"),
            (selector: #selector(self.shareOption), image: "share_colored", text: "Share with friends"),
            (selector: #selector(self.moreGamesOption), image: "games_colored", text: "More games")
            ]
        let views = makeOptionsViews(info)
        self.optionsView.show(type: .TransparentBlack(alpha: 0.70), views: views)
    }
    
    @IBAction func dismissWalkthrough(sender: AnyObject) {
        dismissWalkthrough()
        
    }
}

