//
//  ViewController.swift
//  24
//
//  Created by Luis Perez on 10/5/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit
import AVFoundation

// Rational fractions.
typealias Rational = (num : Int, den : Int)

class ViewController: UIViewController {
    
    @IBOutlet weak var answerNumber1Label: UILabel!
    @IBOutlet weak var answerOperationLabel: UILabel!
    @IBOutlet weak var answerNumber2Label: UILabel!
    // if users taps a filled answer
    @IBOutlet var tappedAnswer1: UITapGestureRecognizer!
    @IBOutlet var tappedOperation: UITapGestureRecognizer!
    @IBOutlet var tappedAnswer2: UITapGestureRecognizer!
    
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var newSetButton: UIButton!
    
    @IBOutlet weak var number1Button: UIButton!
    @IBOutlet weak var number2Button: UIButton!
    @IBOutlet weak var number3Button: UIButton!
    @IBOutlet weak var number4Button: UIButton!
    
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var multiplyButton: UIButton!
    @IBOutlet weak var divideButton: UIButton!
    
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var soundIcon: UIImageView!
    
    var answersFilled = 0
    var numbersLeft = 4
    var currentNumbers = [Int:Int]()
    
    
    // sound related variables
    var silent = false
    var player: AVAudioPlayer?
    var backgroundMusicPlayer = AVAudioPlayer()
    let pop = NSBundle.mainBundle().URLForResource("pop", withExtension: "mp3")!
    let glassPing = NSBundle.mainBundle().URLForResource("calculated", withExtension: "mp3")!
    let computerMistake = NSBundle.mainBundle().URLForResource("computer_error", withExtension: "mp3")!
    let congrats = NSBundle.mainBundle().URLForResource("congrats", withExtension: "mp3")!
    let ambientSound = NSBundle.mainBundle().URLForResource("background_music", withExtension: "mp3")!
    let fail = NSBundle.mainBundle().URLForResource("fail1", withExtension: "mp3")!
    
    // seconds to wait
    let triggerTime = Int64(500000000)
    
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
            return
        }
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
    
    @IBAction func turnOnOffAudio(sender: AnyObject) {
        // if currently not silent
        if silent == false {
            // make silent
            silent = true
            muteButton.setTitle(" UNMUTE", forState: .Normal)
            soundIcon.image = UIImage(named: "mute_white")
        }
        else {
            print("turning sound on")
            silent = false
            muteButton.setTitle("    MUTE", forState: .Normal)
            soundIcon.image = UIImage(named: "sound_white")
        }
        startStopBackgroundMusic()
    }
    
    
    // end testing sound


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        initializeNumbers()
        playBackgroundMusic(ambientSound)
        
        // make sure the mute button has text left aligned
        muteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initializeNumbers() {
        numbersLeft = 4
        clearAnswers()

        // initalize numbers to random between 1 and 9
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        for button in numberButtons {
            let randomNumber = Int(arc4random_uniform(9) + 1)
            button.setTitle(String(randomNumber), forState: .Normal)
            currentNumbers[button.tag] = randomNumber
            // make sure the button has a background
        button.setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
        }
    }
    
    func clearAnswers(){
        answerNumber1Label.text = " "
        answerNumber2Label.text = " "
        answerOperationLabel.text = " "
        
        answersFilled = 0
    }
    
    // Helper functions
    
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
    
    func parseFromString(text: String) -> Double {
        let comps = text.componentsSeparatedByString("/")
        if comps.count == 1 {
            return Double(text)!
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
    
    func computeAnswer() {
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        // make calculation for new number
        let number1 = parseFromString(answerNumber1Label.text!)
        let number2 = parseFromString(answerNumber2Label.text!)
        
        var answer: Double = 0.0
        
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
                return clearBoard("")
            }
            answer = number1 / number2
        }
        
        numberButtons[Int(answerNumber2Label.tag)].setTitle(formatAsString(answer), forState: .Normal)
        
        numberButtons[Int(answerNumber2Label.tag)].setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
    
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
    
    // populate the labels
    @IBAction func populateAnswers(sender: AnyObject) {
        
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        if answerNumber1Label.text == " " {
            answersFilled = answersFilled + 1;
            answerNumber1Label.text = sender.currentTitle!
            answerNumber1Label.tag = sender.tag
            //play pop sound
            playSound(pop)
            
            // set the number label to blank
            // tag maps to index of buttons
            numberButtons[Int(sender.tag)].setTitle(" ", forState: .Normal)
            // sets number button to blank background color
            numberButtons[Int(sender.tag)].setBackgroundImage(nil, forState: .Normal)
        }
        else if answerNumber2Label.text == " " {
            //play pop sound
            playSound(pop)
            answersFilled = answersFilled + 1
            answerNumber2Label.tag = sender.tag
            answerNumber2Label.text = sender.currentTitle!;
            // set number label to blank
            numberButtons[Int(sender.tag)].setTitle(" ", forState: .Normal)
            // sets number button to blank background color
            numberButtons[Int(sender.tag)].setBackgroundImage(nil, forState: .Normal)
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
        if answerOperationLabel.text == " " {
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
    
    @IBAction func reset(sender: AnyObject) {
        numbersLeft = 4
        
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        for button in numberButtons {
            let originalNumber = Int(currentNumbers[button.tag]!)
            button.setTitle(String(originalNumber), forState: .Normal)
        button.setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
        }
        
        clearAnswers()
        
    }
    
    
    @IBAction func clearBoard(sender: AnyObject) {
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        // Move selected numbers back to board
        if answerNumber1Label.text != " "{
            
            // make the number button reappear
            numberButtons[answerNumber1Label.tag].setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
            numberButtons[answerNumber1Label.tag].setTitle(answerNumber1Label.text, forState: .Normal)
            
        }
        if answerNumber2Label.text != " "{
            // make the number button reappear
            numberButtons[answerNumber2Label.tag].setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
            numberButtons[answerNumber2Label.tag].setTitle(answerNumber2Label.text, forState: .Normal)
        }
        
        clearAnswers()
    }
    
    @IBAction func newSet(sender: AnyObject) {
        initializeNumbers()
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
        
        reset("")
        
        
    }


}

