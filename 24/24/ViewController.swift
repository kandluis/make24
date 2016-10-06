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

// Rational fractions.
typealias Rational = (num : Int, den : Int)

class ViewController: UIViewController {
    
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
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var soundIcon: UIImageView!
    
    // Gameplay related variables
    var answersFilled: Int = 0
    var numbersLeft: Int = 4
    var currentNumbers = [Int:Int]()
    
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
    
    // Persistent storage variables
    var problems = [NSManagedObject]()

    /*********
     * View Class Functions
     *********/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeNumbers()
        playBackgroundMusic(ambientSound)
        
        // make sure the mute button has text left aligned
        muteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        
        // Tap gesture for answer1 and operation
        answerNumber1Label.userInteractionEnabled = true
        answerNumber1Label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapAnswer)))
        answerOperationLabel.userInteractionEnabled = true
        answerOperationLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ViewController.tapOperation)))
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Problem")
        
        do {
            let results =
                try managedContext.executeFetchRequest(fetchRequest)
            problems = results as! [NSManagedObject]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    func initializeNumbers() {
        for problem in problems {
            print(problem.valueForKey("problem"))
        }
        clearAnswers()

        // initalize numbers to random between 1 and 9
        numberButtons = [number1Button, number2Button, number3Button, number4Button]
        for button in numberButtons {
            let randomNumber = Int(arc4random_uniform(9) + 1)
            button.setTitle(String(randomNumber), forState: .Normal)
            currentNumbers[button.tag] = randomNumber
            // make sure the button has a background
        button.setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
        }
        
        numbersLeft = 4
    }
    
    func computeAnswer() {
        // make calculation for new number
        let parse1: Double? = parseFromString(answerNumber1Label.text!)
        let parse2: Double? = parseFromString(answerNumber2Label.text!)
        
        if parse1 == nil || parse2 == nil {
            print("Could not parse answers!")
            return
        }
        
        var answer: Double = 0.0
        let number1: Double = parse1!
        let number2: Double = parse2!
        if answerOperationLabel.text == "+" {
            answer = number1 + number2
        }
        else if answerOperationLabel.text == "-" {
            answer = number1 - number2
        }
        else if answerOperationLabel.text == "x" {
            answer = number1 * number2
        }
        else if answerOperationLabel.text == "/" {
            if number2 == 0 {
                startStopBackgroundMusic()
                
                let alert = UIAlertController(title: "Invalid Operation", message: "Division by zero is not allowed! ", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: {(alert: UIAlertAction!) in self.startStopBackgroundMusic()}))
                self.presentViewController(alert, animated: true, completion: nil)
                playSound(computerMistake)
                return clearBoard()
            }
            answer = number1 / number2
        }
        
        setNumberButton(answerNumber2Label.tag, text: formatAsString(answer))
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
    func tapAnswer() {
        if answerNumber1Label.text != " " {
            setNumberButton(answerNumber1Label.tag, text: answerNumber1Label.text!)
            answerNumber1Label.text = " "
            playSound(pop)
        }
    }
    
    func tapOperation() {
        if answerOperationLabel != " " {
            answerOperationLabel.text = " "
            playSound(pop)
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
    
    /************
     * Integer functions
     ************/
    // LCM for Double using continued fraction approximation for fast convergence.
    // For more about this method, see: https://en.wikipedia.org/wiki/Continued_fraction
    // For code see: http://stackoverflow.com/questions/28349864/algorithm-for-lcm-of-doubles-in-swift/28352004#28352004
    func rationalApproximationOf(x0: Double, withPrecision eps: Double = 1.0E-6) -> Rational {
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
    
    func formatAsString(num: Double) -> String {
        let res: Rational = rationalApproximationOf(num)
        if res.den == 1 {
            return String(res.num)
        }
        
        return String(format:"%d/%d", res.num, res.den)
    }
    
    func parseFromString(text: String) -> Double? {
        let comps = text.componentsSeparatedByString("/")
        if comps.count == 1 {
            return Double(text)
        }
        else {
            if comps.count > 2 {
                // Error! Log it!
                print("Fraction too large. See", text)
            }
        
            // A fraction, convert to double ourselves
            let num = Double(comps[0])!
            let den = Double(comps[1])!
        
            return num / den
        }
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
}

