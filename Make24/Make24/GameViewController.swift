//
//  GameViewController.swift
//  Make24
//
//  Created by Luis Perez on 10/4/16.
//  Copyright (c) 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    @IBOutlet weak var answerNumber1Label: UILabel!
    @IBOutlet weak var answerOperationLabel: UILabel!
    @IBOutlet weak var answerNumber2Label: UILabel!
    
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
    @IBOutlet weak var optionsButton: UIButton!
    
    var answersFilled = 0
    var numbersLeft = 4
    var currentNumbers = [Int:Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initializeNumbers()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
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
        }
    }
    
    func clearAnswers(){
        answerNumber1Label.text = " "
        answerNumber2Label.text = " "
        answerOperationLabel.text = " "
        
        answersFilled = 0
    }
    
    func computeAnswer() {
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        // sleep
            
        // make calculation for new number
        let number1 = Int(answerNumber1Label.text!)
        let number2 = Int(answerNumber2Label.text!)
            
        if number1 == nil || number2 == nil {
            print("error occured")
        }
        var answer = 0
        
        if answerOperationLabel.text == "+" {
            answer = number1! + number2!
        }
        else if answerOperationLabel.text == "-" {
            answer = number1! - number2!
        }
        else if answerOperationLabel.text == "x" {
            answer = number1! * number2!
        }
        else if answerOperationLabel.text == "/" {
            if number2! == 0 {
                let alert = UIAlertController(title: "Invalid Operation", message: "Division by zero is not allowed! ", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                return clearBoard("")
            }
            answer = number1! / number2!
        }
        numberButtons[Int(answerNumber2Label.tag)].setTitle(String(answer), forState: .Normal)
    
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
    }
    
    // populate the labels
    @IBAction func populateAnswers(sender: AnyObject) {
        
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        if answerNumber1Label.text == " " {
            answersFilled = answersFilled + 1;
            answerNumber1Label.text = sender.currentTitle!
            answerNumber1Label.tag = sender.tag
            // set the number label to blank
            // tag maps to index of buttons
            numberButtons[Int(sender.tag)].setTitle(" ", forState: .Normal)
        }
        else if answerNumber2Label.text == " " {
            answersFilled = answersFilled + 1
            answerNumber2Label.tag = sender.tag
            answerNumber2Label.text = sender.currentTitle!;
            numberButtons[Int(sender.tag)].setTitle(" ", forState: .Normal)
        }
        else {
            // Do nothing
        }
        
        if answersFilled == 3 {
            computeAnswer()
        }
    }
    
    @IBAction func populateOperation(sender: AnyObject) {
        if answerOperationLabel.text == " " {
            answersFilled = answersFilled + 1;
        }
        answerOperationLabel.text = sender.currentTitle!;
        
        if answersFilled == 3 {
            computeAnswer()
        }
    }
    
    @IBAction func reset(sender: AnyObject) {
        numbersLeft = 4
        
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        for button in numberButtons {
            let originalNumber = Int(currentNumbers[button.tag]!)
            button.setTitle(String(originalNumber), forState: .Normal)
        }
    
        clearAnswers()
        
    }
    
    @IBAction func clearBoard(sender: AnyObject) {
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        // Move selected numbers back to board
        if answerNumber1Label.text != " "{
            numberButtons[answerNumber1Label.tag].setTitle(answerNumber1Label.text, forState: .Normal)
        }
        if answerNumber2Label.text != " "{
            numberButtons[answerNumber2Label.tag].setTitle(answerNumber2Label.text, forState: .Normal)
        }
        
        clearAnswers()
    }
    
    @IBAction func newSet(sender: AnyObject) {
        initializeNumbers()
    }
    
    func congratulations() {
        let alert = UIAlertController(title: "Congratulations!", message: "You won!! Yays!! ", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Play Again", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        print(scoreLabel.text)
        scoreLabel.text = String(Int(scoreLabel.text!)! + 1)
    
        initializeNumbers()
    }
    
    func fails() {
        let alert = UIAlertController(title: "You Failed", message: "Sorry kid!", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
        reset("")

    }
}
