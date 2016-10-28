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



extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension Double {
    fileprivate typealias Rational = (num: Int, den: Int)
    
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
        let comps = text.components(separatedBy: "/")
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
    fileprivate func rationalApproximationOf(_ x0: Double, withPrecision eps: Double = 1.0E-6) -> Rational {
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
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var scoreLabel: UILabel!
    
    // Gameplay related variables
    var answersFilled: Int = 0
    var numbersLeft: Int = 4
    var currentNumbers = [Int:Int]()
    var playerLevel: Int = 1 {
        didSet(oldValue) {
            // Safeguards
            if playerLevel >= 1 && playerLevel <= maxLevel {
                defaults.set(playerLevel, forKey: "level")
            }
            else {
                playerLevel = oldValue
            }
        }
    }
    var puzzlesSolved: Int = 0 {
        didSet(oldValue) {
            if puzzlesSolved >= 0 && puzzlesSolved <= puzzlesPerLevel {
                defaults.set(puzzlesSolved, forKey: "puzzles")
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
                defaults.set(playerScore, forKey: "score")
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
    let defaults = UserDefaults.standard
    
    // Seconds to wait on  transitions.
    let TRIGGERTIME = Int64(500000000)
    
    // Views
    let optionsView = TKSwarmAlert(backgroundType: TKSWBackgroundType.transparentBlack(alpha: 0.70))

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
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if !delegate.hasAppLaunchedBefore(){
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
    
    /******
     * Settings Functions
     ******/
    func loadSettings(){
        // Sound
        silent = defaults.bool(forKey: "silent")
        playerLevel = defaults.integer(forKey: "level")
        playerScore = defaults.integer(forKey: "score")
        puzzlesSolved = defaults.integer(forKey: "puzzles")
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
    func tapAnswer(_ label: UILabel) {
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
        answerNumber1Background.image = UIImage(named: "groove_large")
    }
    func tapAnswer2(){
        tapAnswer(answerNumber2Label)
        answerNumber2Background.image = UIImage(named: "groove_large")
    }
    
    func tapOperation() {
        if let text = answerOperationLabel.text {
            if text.trim() != "" {
                answerOperationLabel.text = " "
                playSound(pop)
                answersFilled -= 1
                answerNumber1Background.image = UIImage(named: "groove_small")
                
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
    func getDifficultyRange(_ level: Int) -> (Double, Double) {
        let maxLevel = Double(self.maxLevel)
        let level = Double(self.playerLevel)
        let max = level / maxLevel
        return (max - 1 / maxLevel, max)
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
    
    func formatPuzzleToString (puzzle: [Int:Int]) -> String {
        var puzzleString = ""
        for (_, puzzleNumber) in puzzle {
            puzzleString = puzzleString + " " + String(puzzleNumber) + " "
        }
        return puzzleString
    }
    //
    func initializeNumbers() {
        
        clearAnswers()
        if let problem = (selectProblem(loadProblems(playerLevel))?.value(forKey: "numbers") as? [Int]) {
            
            for index in 0..<numberButtons.count {
                let selectedNumber = problem[index]
                setNumberButton(index, text: String(problem[index]))
                currentNumbers[index] = selectedNumber
            }
            let puzzleString = formatPuzzleToString(puzzle: currentNumbers)
            defaults.set(puzzleString, forKey: "puzzle")
            
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
            let alert = UIAlertController(title: "Out of problems!", message: "You've run out of problems! Sending you back to square 1!", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
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
                
                let alert = UIAlertController(title: "Invalid Operation", message: "Division by zero is not allowed! ", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
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
    func getAlertTypeOnWin() -> String {
        if puzzlesSolved == puzzlesPerLevel - 1 {
            if playerLevel == maxLevel {
                showConfetti()
                // wait for confetti to finish
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
                    return "finish"
                })
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
        presentAlert(getAlertTypeOnWin())
        
        // Update player info
        puzzlesSolved += 1
        playerScore += 1
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
    func presentAlert(_ alert_type: String){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let myAlert = storyboard.instantiateViewController(withIdentifier: "alert") as? CongratulationsViewController {
            myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
            myAlert.setOptions(alertStringIdentifier: alert_type, currentLevel: playerLevel, puzzlesSolved: puzzlesSolved + 1, completion: {[unowned self](buttonText: String?) -> Void in
                if let text = buttonText {
                    if text == "Leaderboard" {
                        self.showLeaderboard()
                    }
                }
                self.startStopBackgroundMusic()
                })
            self.present(myAlert, animated: true, completion: nil)
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
        if text.characters.count > 2 {
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
        
        answerNumber1Background.image = UIImage(named:"groove_large")
        answerNumber2Background.image = UIImage(named:"groove_large")
        answerOperationBackground.image = UIImage(named:"groove_small")
        
        answersFilled = 0
    }
    func setNumberButton(_ index: Int, text: String) {
        let button = numberButtons[index]
        button?.setBackgroundImage(UIImage(named:"tile_large")!, for: UIControlState())
        button?.titleLabel?.font = getFont(text, currentFont: button?.titleLabel?.font)
        button?.titleLabel?.adjustsFontSizeToFitWidth = true
        button?.contentVerticalAlignment = UIControlContentVerticalAlignment.fill
        button?.titleLabel?.textAlignment = .center
        button?.setTitle(text, for: UIControlState())
        button?.isEnabled = true
    }
    
    func clearNumberButton(_ index: Int){
        numberButtons[index].setTitle(" ", for: UIControlState())
        // sets number button to blank background color
    numberButtons[index].setBackgroundImage(UIImage(named:"groove_large"), for: UIControlState())
        numberButtons[index].isEnabled = false
//        numberButtons[index].setBackgroundImage(nil, for: UIControlState())
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
        let message = "You have declined to login. Please login through the Game Center App or restart the application to be asked to login."
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in })
        self.present(alert, animated: true, completion: completion)
    }
    func showLeaderboard() {
        if let authenticated = localPlayer?.isAuthenticated {
            if authenticated {
                self.reportIfHigher(gameScore: self.playerScore, afterReport: { [unowned self] in
                    self.showLeaderboardView()
                    })
            }
            else {
                self.alertUserAboutLogin(after: nil)
            }
        }
        else {
            authenticateLocalPlayer(afterAuthScreen: nil)
        }
    }
    func authenticateLocalPlayer(afterAuthScreen completion: Closure?) {
        localPlayer = GKLocalPlayer.localPlayer()
        localPlayer?.authenticateHandler = {(viewController, error) -> Void in
            if (viewController != nil) {
                self.present(viewController!, animated: true, completion: completion)
            }
            if let error = error {
                print("Error authenticating player \(error)")
                print(error.localizedDescription)
                if error._code == 2 {
                    self.alertUserAboutLogin(after: completion)
                }
            }
        }
        
    }

    func reportIfHigher(gameScore: Int, afterReport completion: Closure?) {
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
    
    /* GKGameCenterlDelgate Function */
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
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
    func createOptionsView(_ viewTapped: UITapGestureRecognizer,  image_name: String, text: String, frame: CGRect)  ->  OptionView {
        
        
        let newView = OptionView(type: OptionViewType.bar(icon:UIImage(named: image_name), text:text), frame: frame)
        
        viewTapped.numberOfTapsRequired = 1
        newView.isUserInteractionEnabled = true
        newView.addGestureRecognizer(viewTapped)
        
        return newView
        
    }
    typealias ViewInfo = (selector: Selector, image: String, text: String)
    func makeOptionsViews(_ viewInfo: [ViewInfo])->[UIView] {
        let height:CGFloat = 54
        let width:CGFloat = 300
        let margin:CGFloat = 10
        let x:CGFloat = self.view.frame.width / 2 - width/2
        let y:CGFloat = 160
        
        return viewInfo.enumerated().map({(i, info) -> UIView in
            let rect = CGRect(x: x, y: y + (height + margin) * CGFloat(i), width: width, height: height)
            
            let tap = UITapGestureRecognizer(target: self, action: info.selector)
            let view = createOptionsView(tap, image_name: info.image, text: info.text, frame: rect)
            view.backgroundColor = UIColor(red: 247/255, green: 243/255, blue: 228/255, alpha: 1)
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
    func changeModesOption() {
        // TODO: Implement ads
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.showModes()
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
            rateApp()
        }
        self.optionsView.hide()
    }
    func shareOption(){
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            let message = "I'm playing this new, awesome game! Check it out!"
            shareApp(view: self, message: message)
        }
        self.optionsView.hide()
    }
    func soundToggle(){
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.silent = !self.silent
            self.defaults.set(self.silent, forKey: "silent")
        }
        self.optionsView.hide()
    }
    
    /***********
     * Share Options
     ***********/
//    func shareApp() {
//        let textToShare = "I'm playing this new, awesome game! Check it out!"
//        
//        if let myWebsite = URL(string: "http://www.codingexplorer.com/") {
//            let objectsToShare = [textToShare, myWebsite] as [Any]
//            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
//            
//            //New Excluded Activities Code
//            activityVC.excludedActivityTypes = [UIActivityType.airDrop, UIActivityType.addToReadingList]
//            
//            // TODO: for ipad
//            // activityVC.popoverPresentationController?.sourceView = sender as! UIView
//            self.present(activityVC, animated: true, completion: nil)
//        }
//    }
    
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
        answerOperationBackground.image = UIImage(named:"tile_small")
        
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
        showLeaderboard()
        
    }
    @IBAction func showOptions(_ sender: AnyObject) {
        let muteButtonText = silent ? "Unmute" : "Mute"
        let soundIcon = silent ? "mute" : "sound_grey"

        
        let info = [
            (selector: #selector(self.leaderBoardOption), image: "leaderboard", text: "Leaderboard"),
            (selector: #selector(self.soundToggle), image: soundIcon, text: muteButtonText),
            (selector: #selector(self.tutorialOption), image: "tutorial", text: "Tutorial"),
            (selector: #selector(self.rateOption), image: "rate", text: "Rate the app"),
            (selector: #selector(self.shareOption), image: "share", text: "Share with friends"),
            (selector: #selector(self.changeModesOption), image: "modes", text: "Change Difficulty Level")
            ]
        let views = makeOptionsViews(info)
        self.optionsView.show(views)
    }
    func showModes() {
        let info = [
            (selector: #selector(self.setEasyMode), image: "easy", text: "Easy"),
            (selector: #selector(self.setMediumMode), image: "medium", text: "Medium"),
            (selector: #selector(self.setHardMode), image: "hard", text: "Hard")
        ]
        let views = makeOptionsViews(info)
        self.optionsView.show(views)

    }
    
    func setEasyMode() {
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.defaults.set("easy", forKey: "mode")
            print(self.defaults.string(forKey: "mode"))
        }
        self.optionsView.hide()
        
        // TODO implement actual mode changing
    }
    
    func setMediumMode() {
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.defaults.set("medium", forKey: "mode")
            print(self.defaults.string(forKey: "mode"))
        }
        self.optionsView.hide()
        
        // TODO implement actual mode changing
    }
    func setHardMode() {
        self.optionsView.didDissmissAllViews = { [unowned self] in
            self.optionsView.didDissmissAllViews = {}
            self.defaults.set("hard", forKey: "mode")
            print(self.defaults.string(forKey: "mode"))
        }
        self.optionsView.hide()
        // TODO implement actual mode changing
    }
    
    @IBAction func dismissWalkthrough(_ sender: AnyObject) {
        dismissWalkthrough()
        
    }
    
    // Apple watch stuff
    private let session: WCSession? = WCSession.isSupported() ? WCSession.default() : nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        configureWCSession()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        configureWCSession()
    }
    
    private func configureWCSession() {
        session?.delegate = self;
        session?.activate()
    }
    

    //Handlers in case the watch and phone watch connectivity session becomes disconnected
    func sessionDidDeactivate(_ session: WCSession) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func showConfetti() {
        let confettiView = SAConfettiView(frame: self.view.bounds)
        confettiView.startConfetti()
        self.view.addSubview(confettiView)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            confettiView.stopConfetti()
            // preferrably wait until above is finished
            confettiView.removeFromSuperview()
        })
    }
    
    // when player whens the game
    @IBAction func showConfetti(_ sender: Any) {
        showConfetti()
    }
    
}

