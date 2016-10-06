//
//  ViewController.swift
//  24
//
//  Created by Luis Perez on 10/5/16.
//  Copyright © 2016 Luis PerezBunnyLemon. All rights reserved.
//

import UIKit

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
    @IBOutlet weak var optionsButton: UIButton!
    
    var answersFilled = 0
    var numbersLeft = 4
    var currentNumbers = [Int:Int]()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        initializeNumbers()

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
    
    func computeAnswer() {
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        // sleep
        
        // make calculation for new number
        let number1 = Double(answerNumber1Label.text!)
        let number2 = Double(answerNumber2Label.text!)
        
        if number1 == nil || number2 == nil {
            print("error occured")
        }
        var answer: Double = 0.0
        
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
            // sets number button to blank background color
            numberButtons[Int(sender.tag)].setBackgroundImage(nil, forState: .Normal)
        }
        else if answerNumber2Label.text == " " {
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
        button.setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
        }
        
        clearAnswers()
        
    }
    
    
    @IBAction func clearBoard(sender: AnyObject) {
        let numberButtons = [number1Button, number2Button, number3Button, number4Button]
        
        // Move selected numbers back to board
        if answerNumber1Label.text != " "{
            
            // make the number button reappear
            numberButtons[Int(sender.tag)].setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
            numberButtons[answerNumber1Label.tag].setTitle(answerNumber1Label.text, forState: .Normal)
            
        }
        if answerNumber2Label.text != " "{
            // make the number button reappear
            numberButtons[Int(sender.tag)].setBackgroundImage(UIImage(named:"tile_large")!, forState: .Normal)
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

