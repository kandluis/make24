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
import WatchConnectivity
import SAConfettiView
import Mixpanel

enum GameDifficulty: Int, CaseCountable {
    case easy = 0
    case medium = 1
    case hard =  2
    
    static let caseCount = GameDifficulty.countCases()
}

enum KeyForSetting: String {
    case silent = "silent"
    case difficulty = "diffculty"
    case score = "score"
    case rated =  "rated"
    case problem = "problem"
    
    // Do not use directly. Instead use corresponding xKey() function.
    case internalPuzzle = "puzzle"
    case internalLevel = "level"
}

class ViewController: UIViewController, GKGameCenterControllerDelegate, WCSessionDelegate {
    
    // Answer board area.
    @IBOutlet weak var answerNumber1Label: UILabel!
    @IBOutlet weak var answerOperationLabel: UILabel!
    @IBOutlet weak var answerNumber2Label: UILabel!
    @IBOutlet weak var answerNumber1Background: UIImageView!
    @IBOutlet weak var answerOperationBackground: UIImageView!
    @IBOutlet weak var answerNumber2Background: UIImageView!
    
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
    @IBOutlet weak var leaderBoardButton: UIButton!
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    // Difficulty Options
    @IBOutlet weak var difficultyLabel: UILabel!
    @IBOutlet weak var difficultyImage: UIImageView!
    
    // Gameplay related variables
    var answersFilled: Int = 0
    var numbersLeft: Int = 4
    var currentNumbers = [Int:Int]()

    var difficulty: GameDifficulty = GameDifficulty.easy {
        willSet(newValue) {
            defaults.set(newValue.rawValue, forKey: KeyForSetting.difficulty.rawValue)
        }
        didSet(oldValue) {
            // Update display properties.
            updateInternalProgress()
            
            
            // Determine image and text to use.
            switch difficulty {
            case .easy:
                difficultyLabel.text = NSLocalizedString("Easy", comment: "String shown in difficulty ui (keep short)")
                difficultyImage.image = #imageLiteral(resourceName: "easy")
            case .medium:
                difficultyLabel.text = NSLocalizedString("Med.", comment: "String shown in difficulty ui (keep short)")
                difficultyImage.image = #imageLiteral(resourceName: "medium")
            case .hard:
                difficultyLabel.text = NSLocalizedString("Hard", comment: "String shown in difficulty ui (keep short)")
                difficultyImage.image = #imageLiteral(resourceName: "hard")
                
            }
            difficultyLabel.sizeToFit()
            difficultyImage.bounds.size = difficultyImage.image!.size
            difficultyImage.center.x = difficultyLabel.frame.origin.x - difficultyImage.bounds.size.width / 2 - 4
        }
    }
    var playerLevel: Int = 1 {
        didSet(oldValue) {
            // Safeguards
            if playerLevel >= 1 && playerLevel <= levelsPerDifficulty {
                defaults.set(playerLevel, forKey: levelKey())
            }
            else {
                playerLevel = oldValue
            }
        }
    }
    var puzzlesSolved: Int = 0 {
        didSet(oldValue) {
            if puzzlesSolved >= 0 && puzzlesSolved <= puzzlesPerLevel {
                defaults.set(puzzlesSolved, forKey: puzzleKey())
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
                defaults.set(playerScore, forKey: KeyForSetting.score.rawValue)
            }
            else {
                playerScore = oldValue
            }
        }
    }
    let levelsPerDifficulty: Int = 10
    let puzzlesPerLevel: Int = 10
    var silent: Bool = false {
        didSet {
            syncMusic()
            
        }
    }
    // Current problem from db
    var selectedProblem: NSManagedObject?
    
    // Audio variables
    var player: AVAudioPlayer? = nil
    var backgroundMusicPlayer = AVAudioPlayer()
    let pop = Bundle.main.url(forResource: "pop", withExtension: "mp3")!
    let glassPing = Bundle.main.url(forResource: "calculated", withExtension: "mp3")!
    let computerMistake = Bundle.main.url(forResource: "computer_error", withExtension: "mp3")!
    let congrats = Bundle.main.url(forResource: "congrats", withExtension: "mp3")!
    let ambientSound = Bundle.main.url(forResource: "background_music", withExtension: "mp3")!
    let fail = Bundle.main.url(forResource: "fail1", withExtension: "mp3")!
    
    // User defaults
    let defaults: UserDefaults! = UserDefaults(suiteName: "group.bunnylemon.24")
    
    // Seconds to wait on  transitions.
    let TRIGGERTIME = Int64(500000000)
    
    // Views
    let optionsView = TKSwarmAlert(backgroundType: TKSWBackgroundType.transparentBlack(alpha: 0.70))
    var confettiView: SAConfettiView?


    // Walthrough
    @IBOutlet weak var skipWalkthroughButton: UIButton!
    @IBOutlet weak var walkthroughInstructionsView: UIView!
    var currentHoles = [UIView]()
    
    // Leaderboard
    let LEADER_BOARD_ID = "Overall"
    var onGameCenterDismiss: (() -> Void)?

    /*********
     * View Class Functions
     *********/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for when we go in an out of background.
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.willResignActive), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.didBecomeActive), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        numberButtons = [number1Button, number2Button, number3Button, number4Button]
        optionsView.fadeOutDuration = 1.1
        
        playBackgroundMusic(ambientSound)
        loadSettings()
        initializeNumbers()
        setAnswerTouchTargets()
        
        Mixpanel.mainInstance().track(event: "Launched App")
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // The tutorial must be started after the view has appeared.
        // This is because launching it requires accessing key view
        // components.
        if Utilities.firstLaunch(){
            tutorial()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func willResignActive() {
        // App is always silenced in background.
        silent = true
    }
    
    func didBecomeActive(){
        // Restore user setting.
        silent = defaults.bool(forKey: KeyForSetting.silent.rawValue)
    }
    
    /******
     * Settings Functions
     ******/
    func levelKey() -> String {
        return "\(KeyForSetting.difficulty.rawValue)(\(difficulty.rawValue)):\(KeyForSetting.internalLevel.rawValue)"
    }
    func puzzleKey() -> String {
        return "\(levelKey())(\(playerLevel)):\(KeyForSetting.internalPuzzle.rawValue)"
    }
    // Sets the appropriate values based on an updated game difficulty.
    func updateInternalProgress(){
        playerLevel = defaults.integer(forKey: levelKey())
        if playerLevel == 0 {
            playerLevel = 1
        }
        puzzlesSolved = defaults.integer(forKey: puzzleKey())
    }
    func loadSettings(){
        // Sound
        silent = defaults.bool(forKey: KeyForSetting.silent.rawValue)
        difficulty = GameDifficulty(rawValue: defaults.integer(forKey: KeyForSetting.difficulty.rawValue)) ?? GameDifficulty.easy
        playerScore = defaults.integer(forKey: KeyForSetting.score.rawValue)
        updateInternalProgress()
    }
    
    /*****
     * Touch Targets
     ******/
    func setAnswerTouchTargets(){
        answerNumber1Label.isUserInteractionEnabled = true
        answerNumber1Label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapAnswer1)))
        answerOperationLabel.isUserInteractionEnabled = true
        answerOperationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapOperation)))
        answerNumber2Label.isUserInteractionEnabled = true
        answerNumber2Label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapAnswer2)))
    }
    // We can only ever tap the first answer! f
    func tapAnswer(_ label: UILabel, background: UIImageView) {
        if let text = label.text {
            if text.trim() != "" {
                // Delay for a more natural feel.
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(TRIGGERTIME) / (10 * Double(NSEC_PER_SEC)), execute: { [unowned self]() -> Void in
                    background.image = #imageLiteral(resourceName: "groove_large")
                    label.text = " "
                    self.setNumberButton(label.tag, text: text)
                    self.playSound(self.pop)
                    self.answersFilled -= 1
                    if self.ongoingWalkthrough {
                        self.removeHole(label)
                        self.addHole(holeToAdd: self.numberButtons[label.tag])
                    }
                })
            }
        }
    }
    func tapAnswer1(){
        tapAnswer(answerNumber1Label, background: answerNumber1Background)
    }
    func tapAnswer2(){
        tapAnswer(answerNumber2Label, background: answerNumber2Background)
    }
    
    func tapOperation() {
        if let text = answerOperationLabel.text {
            if text.trim() != "" {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(TRIGGERTIME) / (10 * Double(NSEC_PER_SEC)), execute: {[unowned self] in
                    self.answerOperationLabel.text = " "
                    self.playSound(self.pop)
                    self.answersFilled -= 1
                    self.answerOperationBackground.image = #imageLiteral(resourceName: "groove_small")
                    
                    if self.ongoingWalkthrough {
                        self.removeHole(self.answerOperationLabel)
                        self.addHole(holeToAdd: self.multiplyButton)
                    }
                })
            }
        }
    }
    
    /************
     * Database Functions
     *************/
    func getDifficultyRange(_ level: Int) -> (Double, Double) {
        let buckets = Double(GameDifficulty.caseCount * self.levelsPerDifficulty)
        let level = Double(self.difficulty.rawValue * self.levelsPerDifficulty +  self.playerLevel)
        let max = level / buckets
        return (max - (1 / buckets), max)
    }
    
    func loadProblems(_ level: Int) -> [NSManagedObject] {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return []
        }
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Problem")
        
        // Filter to only include levels not completed
        let (minDifficulty, maxDifficulty) = getDifficultyRange(level)
        fetchRequest.predicate = NSPredicate(format: "completed == %@ AND difficulty > %f AND difficulty < %f", false as CVarArg, minDifficulty, maxDifficulty)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "difficulty", ascending: true)]
        
        var results: [AnyObject]?
        do {
            results =
                try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        return results as? [NSManagedObject] ?? []

    }
    
    /*****************
     * Sound Functions
     *****************/
    func playSound(_ sound: URL) {
        if !silent {
            do {
                player = try AVAudioPlayer(contentsOf: sound)
                guard let player = player else { return }
                
                player.prepareToPlay()
                player.play()
            } catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    func playBackgroundMusic(_ sound: URL) {
        if !silent {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: ambientSound)
                
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
            if backgroundMusicPlayer.isPlaying {
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
    func selectProblem(_ problems: [NSManagedObject]) -> NSManagedObject? {
        print("Selecting from \(problems.count) problems!")
        var selectedProblem: NSManagedObject?
        if problems.count > 0 {
            selectedProblem = problems[Int(arc4random_uniform(UInt32(problems.count)))]
        }
        return selectedProblem
    }

    // format puzzle into strings
    func formatPuzzleToString (_ puzzle: [Int:Int]) -> String {
        var puzzleString = ""
        for (_, puzzleNumber) in puzzle {
            puzzleString = puzzleString + " " + String(puzzleNumber) + " "
        }
        return puzzleString
    }
    func initializeNumbers() {
        
        clearAnswers()
        if let problem = (selectProblem(loadProblems(playerLevel))?.value(forKey: "numbers") as? [Int]) {
            
            for index in 0..<numberButtons.count {
                let selectedNumber = problem[index]
                setNumberButton(index, text: String(problem[index]))
                currentNumbers[index] = selectedNumber
            }
            
            // send data to watch if watch is supported
            if WCSession.isSupported() {
                let msg = ["puzzle": currentNumbers]
                print(msg)
                print(session ?? "")
                self.session?.sendMessage(msg, replyHandler: { (reply)->Void in }, errorHandler: { (reply)->Void in })
                
            }
            
            // Numbers used reset!
            numbersLeft = 4
        }
        else {
            let title = NSLocalizedString("Out of problems!", comment: "Title of alert when user has exhausted all possible problems")
            let message = NSLocalizedString("You've run out of problems! Sending you back to square 1!", comment: "Message presented to the user when they have run out of problems!")
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Acceptance button for alert!"), style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
            self.present(alert, animated: true, completion: nil)
            
            let delegate = UIApplication.shared.delegate as!AppDelegate
            delegate.resetApplication()
            initializeNumbers()
        }
    }
    
    // Operations to perform after an answer has been calcuated successfully.
    func calculatedAnswer(_ answer: Double){
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
                let title = NSLocalizedString("Invalid Operation", comment: "Title of alert when user attempts to divide by 0")
                let message = NSLocalizedString("Division by zero is not allowed!", comment: "Message to user when attempting to divide by 0")
                let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Accept alert buttong"), style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
                self.present(alert, animated: true, completion: nil)
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
    func getAlertTypeOnWin() -> AlertType {
        // puzzlesSolved and difficulty are 0-indexed
        // playerLevel is 1-indexed
        if puzzlesSolved == puzzlesPerLevel - 1 {
            if playerLevel == levelsPerDifficulty {
                if difficulty.rawValue == GameDifficulty.caseCount - 1 {
                    return .finish
                }
                return .next_difficulty
            }
            return .next_level
        }
        return .next_puzzle
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
        let alert_type = getAlertTypeOnWin()
        presentAlert(alert_type)
        
        // Update player info.
        puzzlesSolved += 1
        playerScore += 1
        // Check if level is passed.
        if puzzlesSolved == puzzlesPerLevel {
            playerLevel += 1
            puzzlesSolved = 0
        }
        // Check if difficulty is passed. Recall this is 1-indexed.
        if playerLevel == levelsPerDifficulty + 1 {
            difficulty = GameDifficulty(rawValue: difficulty.rawValue + 1) ?? difficulty
        }
        
        Mixpanel.mainInstance().track(event: "Won Puzzle")
        print(Mixpanel.mainInstance())
    }
    
    func didLose() {
        fails()
    }
    func fails() {
        startStopBackgroundMusic()
        playSound(fail)
        
        presentAlert(.retry)
        reset()
        Mixpanel.mainInstance().track(event: "Failed Puzzle")
    }
    func presentAlert(_ alert_type: AlertType){
        if case .finish = alert_type {
            showConfetti()
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let myAlert = storyboard.instantiateViewController(withIdentifier: "alert") as? CongratulationsViewController {
            myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            myAlert.setOptions(alert: alert_type, currentDifficulty: difficulty, currentLevel: playerLevel, puzzlesSolved: puzzlesSolved + 1, completion: {[unowned self](type: AlertType, action: UserAction?) -> Void in
                let action = action ?? .dismiss
                self.onUserAction(action)
                self.onDismissAlert(type)
                self.startStopBackgroundMusic()
                
            })
            self.present(myAlert, animated: true, completion: nil)
        }
    }
    func onUserAction(_ action: UserAction) {
        switch action {
        case .rate:
            Common.rateApp()
            self.defaults.set(true, forKey: KeyForSetting.rated.rawValue)
        case .challange:
            let puzzleAsString = self.formatPuzzleToString(self.currentNumbers)
            let message = "I challenge you to solve this puzzle! Use all four numbers \(puzzleAsString),and any basic operation (+,-,x,/) to make 24."
            Common.shareApp(self, message: message)
        case .nextLevel:
            if !self.defaults.bool(forKey: KeyForSetting.rated.rawValue) {
                self.presentAlert(AlertType.rate)
            }
        case .leaderboard:
            self.showLeaderboard(attemptAuthentication: true)
            self.onGameCenterDismiss = {[unowned self, previousClosure = self.onGameCenterDismiss] in
                // respect other handlers.
                if let code = previousClosure {
                    code()
                }
                
                if !self.defaults.bool(forKey: KeyForSetting.rated.rawValue) {
                    self.presentAlert(AlertType.rate)
                }
    
                // Reset yourself.
                self.onGameCenterDismiss = nil
            }
        case .ask:
            let puzzleAsString = self.formatPuzzleToString(self.currentNumbers)
            let message = "Can you help me solve this puzzle? Use all four numbers \(puzzleAsString),and any basic operation (+,-,x,/) to make 24."
            Common.shareApp(self, message: message)
        case .keepGoing, .dismiss, .retry:
            break
        }
    }
    func onDismissAlert(_ type: AlertType){
        switch type {
        case .finish:
            self.dismissConfetti()
            // TODO: Inform the user that this is happening!?
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.resetApplication()
        case .next_difficulty, .next_puzzle, .next_level, .retry, .rate:
            break
        }
    }
    
    /*********
     * Graphical Functions
     **********/
    weak var defaultFont: UIFont?
    lazy var fractionFont: UIFont = {
        let size: CGFloat = 60.0
        let defaultFont = UIFont.systemFont(ofSize: size, weight: UIFontWeightLight)
        let systemFontDesc = defaultFont.fontDescriptor
        let fractionFontDesc = systemFontDesc.addingAttributes(
            [
                UIFontDescriptorFeatureSettingsAttribute: [
                    [
                        UIFontFeatureTypeIdentifierKey: kFractionsType,
                        UIFontFeatureSelectorIdentifierKey: kDiagonalFractionsSelector,
                    ],
                ]
            ]
        )
        return UIFont(descriptor: fractionFontDesc, size: size)
    }()
    func getFont(_ text: String, currentFont: UIFont?) -> UIFont {
        if defaultFont == nil {
            defaultFont = currentFont
        }
        if text.contains("/") {
            return fractionFont
        }
        else {
            return defaultFont ?? fractionFont
        }
    }
    
    func clearAnswers(){
        answerNumber1Label.text = " "
        answerNumber2Label.text = " "
        answerOperationLabel.text = " "
        
        answerNumber1Background.image = #imageLiteral(resourceName: "groove_large")
        answerNumber2Background.image = #imageLiteral(resourceName: "groove_large")
        answerOperationBackground.image = #imageLiteral(resourceName: "groove_large")
        
        answersFilled = 0
    }
    func setNumberButton(_ index: Int, text: String) {
        let button = numberButtons[index]
        button?.titleLabel?.font = getFont(text, currentFont: button?.titleLabel?.font)
        button?.titleLabel?.adjustsFontSizeToFitWidth = true
        button?.contentVerticalAlignment = UIControlContentVerticalAlignment.fill
        button?.titleLabel?.textAlignment = .center
        button?.setTitle(text, for: .normal)
        button?.isEnabled = true
        button?.setBackgroundImage(#imageLiteral(resourceName: "tile_large"), for: .normal)
    }
    
    func clearNumberButton(_ index: Int){
        numberButtons[index].setTitle(" ", for: UIControlState())
        // sets number button to blank background color
    numberButtons[index].setBackgroundImage(#imageLiteral(resourceName: "groove_large"), for: UIControlState())
        numberButtons[index].isEnabled = false
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
        for button in numberButtons.enumerated() {
            setNumberButton(button.offset, text: String(currentNumbers[button.element.tag]!))
            
        }
        clearAnswers()
    }

    /************
     * Leaderboard Functions
     ************/
    func alertUserAboutLogin(after completion: Closure?) {
        let title = "Fail Login!"
        let message = "Login has failed multiple times. Please attempt to login through the GameCenter or attempt the action again!"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
        self.present(alert, animated: true, completion: completion)
    }
    func showLeaderboard(attemptAuthentication authenticate: Bool) {
        LoadingOverlay.shared.showOverlay(self.view)
        if GKLocalPlayer.localPlayer().isAuthenticated {
            // Disable user interaction with options/leaderboard.
            optionsButton.isUserInteractionEnabled = false
            leaderBoardButton.isUserInteractionEnabled = false
            self.reportIfHigher(self.playerScore, afterReport: { [unowned self] in
                self.optionsButton.isUserInteractionEnabled = true
                self.leaderBoardButton.isUserInteractionEnabled = true
                LoadingOverlay.shared.hideOverlayView()
                self.showLeaderboardView()
                })
        }
        else if authenticate {
            authenticateLocalPlayer(afterAuthScreen: {[unowned self] in
                self.showLeaderboard(attemptAuthentication: false)
            })
        }
        else {
            alertUserAboutLogin(after: nil)
            LoadingOverlay.shared.hideOverlayView()
        }
    }
    func authenticateLocalPlayer(afterAuthScreen completion: Closure?) {
        GKLocalPlayer.localPlayer().authenticateHandler = {(viewController, error) -> Void in
            if viewController != nil && !GKLocalPlayer.localPlayer().isAuthenticated {
                return self.present(viewController!, animated: true, completion: completion)
            }
            if let error = error {
                print("Error authenticating player \(error)")
                print(error.localizedDescription)
                if error._code == 2 {
                    self.alertUserAboutLogin(after: nil)
                }
            }
            if let code = completion {
                code()
            }
        }
        
    }

    func reportIfHigher(_ gameScore: Int, afterReport completion: Closure?) {
        let leaderboardRequest = GKLeaderboard(players: [GKLocalPlayer.localPlayer()])
        leaderboardRequest.identifier = LEADER_BOARD_ID
        leaderboardRequest.timeScope = GKLeaderboardTimeScope.allTime
        leaderboardRequest.loadScores(completionHandler: {[unowned self](scores, error) -> Void in
            if error == nil {
                if let remoteScore = (scores?[0])?.value {
                    if Int(remoteScore) < gameScore {
                        return self.reportScore(gameScore, afterReport: completion)
                    }
                }
                else {
                   return self.reportScore(gameScore, afterReport: completion)
                }
            }
            if let code = completion {
                code()
            }
        })
    }
    func reportScore(_ score: Int, afterReport completion: Closure?) {
        let scoreReporter = GKScore(leaderboardIdentifier:LEADER_BOARD_ID)
        scoreReporter.value = Int64(score)
        let scoreArray: [GKScore] = [scoreReporter]
        GKScore.report(scoreArray, withCompletionHandler: {error -> Void in
            if error != nil {
                print("An error has occured:")
                print("\n \(error) \n")
            }
            if let code = completion{
                code()
            }
        })
    }
    func showLeaderboardView() {
        let viewControllerVar = self.view?.window?.rootViewController
        let gKGCViewController = GKGameCenterViewController()
        gKGCViewController.gameCenterDelegate = self
        viewControllerVar?.present(gKGCViewController, animated: true, completion: nil)
    }
    
    /* GKGameCenterlDelegate Function */
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: onGameCenterDismiss)
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
        walkthroughInstructionsView.isHidden = false
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
    
    func removeHole(_ element: UIView){
        var holes = currentHoles
        if let index = currentHoles.index(of: element) {
            holes.remove(at: index)
            walkthroughView?.removeAllHoles()
            createHoles(holesToCreate: holes)
        }
    }
    
    func dismissWalkthrough(){
        walkthroughInstructionsView.isHidden = true
        finishWalkthrough()
        loadSettings()
        initializeNumbers()
    }
    
    /*********
     * Options Menu Functions
     *********/
    func createOptionsView(_ viewTapped: UITapGestureRecognizer,  image: UIImage, text: String, frame: CGRect)  ->  OptionView {
        
        
        let newView = OptionView(type: OptionViewType.bar(icon: image, text:text), frame: frame)
        
        viewTapped.numberOfTapsRequired = 1
        newView.isUserInteractionEnabled = true
        newView.addGestureRecognizer(viewTapped)
        
        return newView
        
    }
    typealias ViewInfo = (selector: Selector, image: UIImage, text: String)
    func makeOptionViews(_ viewInfo: [ViewInfo])->[UIView] {
        let totalFit:CGFloat = 10
        let height:CGFloat = min(57, view.frame.size.height / totalFit)
        let width:CGFloat = min(300, 0.8 * view.frame.size.width)
        let margin:CGFloat = height / 6
        let x:CGFloat = self.view.frame.size.width / 2 - width/2
        // center - offset - 10 * 0.5 * (space of single item
        let y:CGFloat = (self.view.frame.size.height / 2) - (height/2.0) - (totalFit * 0.25) * (height + margin)
        
        return viewInfo.enumerated().map({(i, info) -> UIView in
            let rect = CGRect(x: x, y: y + (height + margin) * CGFloat(i), width: width, height: height)
            
            let tap = UITapGestureRecognizer(target: self, action: info.selector)
            let view = createOptionsView(tap, image: info.image, text: info.text, frame: rect)
            view.backgroundColor = UIColor(red: 247/255, green: 243/255, blue: 228/255, alpha: 1)
            return view

        })
    }

    /***** TOP LEVEL OPTION HANDLERS ****/
    func leaderBoardOption() {
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.showLeaderboard(attemptAuthentication: true)
        }
        self.optionsView.hide()
    }
    func changeModesOption() {
        // TODO: Implement ads
        self.showModes()
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
            Common.rateApp()
        }
        self.optionsView.hide()
    }
    func shareOption(){
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            let message = "I'm playing this new, awesome game! Check it out!"
            Common.shareApp(self, message: message)
        }
        self.optionsView.hide()
    }
    func soundToggle(){
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.silent = !self.silent
            self.defaults.set(self.silent, forKey: KeyForSetting.silent.rawValue)
        }
        self.optionsView.hide()
    }
    func showModes() {
        let info = [
            (selector: #selector(self.setEasyMode), image: (difficulty != .easy) ? #imageLiteral(resourceName: "easy"): #imageLiteral(resourceName: "checkmark"), text: "Easy"),
            (selector: #selector(self.setMediumMode), image: (difficulty != .medium) ? #imageLiteral(resourceName: "medium"): #imageLiteral(resourceName: "checkmark"), text: "Medium"),
            (selector: #selector(self.setHardMode), image: (difficulty != .hard) ?#imageLiteral(resourceName: "hard") : #imageLiteral(resourceName: "checkmark"), text: "Hard")
        ]
        let views = makeOptionViews(info)
        self.optionsView.addNextViews(views)
        
    }
    
    /***** SUBMENU OPTION FOR MODE ****/
    func setMode(_ mode: GameDifficulty) {
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            if self.difficulty != mode {
                self.difficulty = mode
                self.initializeNumbers()
            }
        }
        self.optionsView.hide()
    }
    func setEasyMode() {
        setMode(GameDifficulty.easy)
    }
    
    func setMediumMode() {
        setMode(GameDifficulty.medium)
    }
    func setHardMode() {
        setMode(GameDifficulty.hard)
    }
    
    /******
     * User Actions
     ******/
    @IBAction func populateAnswers(_ sender: AnyObject) {
        
        // all else
        guard let text1 = answerNumber1Label.text else { return }
        guard let text2 = answerNumber2Label.text else { return }
        if text1.trim() == "" || text2.trim() == "" {
            let openLabel = text1.trim() == "" ? answerNumber1Label : answerNumber2Label
            let openBackground = text1.trim() == "" ? answerNumber1Background : answerNumber2Background
            
            openBackground?.image = UIImage(named: "tile_large")
            let text = (sender as? UIButton)?.currentTitle ?? ""
            openLabel?.font = getFont(text, currentFont: openLabel?.font)
            openLabel?.adjustsFontSizeToFitWidth = true
            openLabel?.text = text
            openLabel?.tag = ((sender as? UIButton)?.tag)!
            
            // for the walkthrough
            if ongoingWalkthrough {
                removeHole(numberButtons[(openLabel?.tag)!])
                addHole(holeToAdd: openLabel!)
            }
            
            if answersFilled < 3 {
                answersFilled = answersFilled + 1;
            }
            
            playSound(pop)
            clearNumberButton((openLabel?.tag)!)
        }
        else {
            // Do nothing
            playSound(computerMistake)
        }
        
        if answersFilled == 3 {
            // delay so user can see full answers
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(TRIGGERTIME) / Double(NSEC_PER_SEC), execute: { () -> Void in
                self.computeAnswer()
            })
        }
    }
    
    @IBAction func populateOperation(_ sender: AnyObject) {
        guard let text = answerOperationLabel.text else { return }
        if text.trim() == "" && answersFilled < 3 {
            answersFilled = answersFilled + 1
        }
        answerOperationBackground.image = #imageLiteral(resourceName: "tile_small")
        
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
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(TRIGGERTIME) / Double(NSEC_PER_SEC), execute: { () -> Void in
                self.computeAnswer()
            })
        }
    }
    
    @IBAction func resetButton(_ sender: AnyObject) {
        reset()
    }
    
    @IBAction func clearBoardButton(_ sender: AnyObject) {
        clearBoard()
        
    }
    
    @IBAction func newSet(_ sender: AnyObject) {
        initializeNumbers()
    }
    
    @IBAction func showLeader(_ sender: AnyObject) {
        showLeaderboard(attemptAuthentication: true)
        
    }
    @IBAction func showOptions(_ sender: AnyObject) {
        let muteButtonText = silent ? NSLocalizedString("Unmute", comment: "Text shown when unmuting the sound") : NSLocalizedString("Mute", comment: "Text shown when muting")
        let soundIcon = silent ? #imageLiteral(resourceName: "mute") : #imageLiteral(resourceName: "sound_brown")
        
        let info = [
            (selector: #selector(self.leaderBoardOption), image: #imageLiteral(resourceName: "leaderboard"), text: NSLocalizedString("Leaderboard", comment: "Text shown for the leaderboard option")),
            (selector: #selector(self.soundToggle), image: soundIcon, text: muteButtonText),
            (selector: #selector(self.tutorialOption), image: #imageLiteral(resourceName: "tutorial"), text: NSLocalizedString("Tutorial", comment: "Text shown for the tutorial option")),
            (selector: #selector(self.rateOption), image: #imageLiteral(resourceName: "rate"), text: NSLocalizedString("Rate the app", comment: "Text shown for the option to rate the app.")),
            (selector: #selector(self.shareOption), image: #imageLiteral(resourceName: "share"), text: NSLocalizedString("Share with friends", comment: "Text shown for the option to share the app with friends.")),
            (selector: #selector(self.changeModesOption), image: #imageLiteral(resourceName: "modes"), text: NSLocalizedString("Change Difficulty Level", comment: "Text shown for the option to change difficulty level"))]
        let views = makeOptionViews(info)
        self.optionsView.show(views)
    }
    
    @IBAction func dismissWalkthrough(_ sender: AnyObject) {
        dismissWalkthrough()
        
    }
    
    // Apple watch stuff
    fileprivate let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureWCSession()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        configureWCSession()
    }
    
    fileprivate func configureWCSession() {
        session?.delegate = self;
        session?.activate()
    }
    

    //Handlers in case the watch and phone watch connectivity session becomes disconnected
    func sessionDidDeactivate(_ session: WCSession) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func showConfetti() {
        if confettiView == nil {
            confettiView = SAConfettiView(frame: self.view.bounds)
        }
        self.view.addSubview(confettiView!)
        confettiView!.startConfetti()
    }
    func dismissConfetti() {
        confettiView?.stopConfetti()
        confettiView?.removeFromSuperview()
    }    
}

