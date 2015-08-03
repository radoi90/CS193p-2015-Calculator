//
//  ViewController.swift
//  Calculator
//
//  Created by Emil Culic on 10/06/2015.
//  Copyright (c) 2015 Emil Culic. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    @IBOutlet weak var descriptionDisplay: UILabel!
    
    @IBOutlet weak var display: UILabel!
    
    var userIsInTheMiddleOfTypingANumber = false
    
    var brain = CalculatorBrain()
    
    let defaultDisplayText = "0"
    let defaultDescriptionText = ""

    @IBAction func appendCharacter(sender: UIButton) {
        let character = sender.currentTitle!
        
        switch character {
        case ".":
            appendDecimalPoint()
        case let digit where (0...9).map { "\($0)" }.contains(digit):
            appendDigit(digit)
        case "ᐩ/-":
            if userIsInTheMiddleOfTypingANumber {
                toggleNegativeSign()
            } else {
                operate(sender)
            }
        default: break
        }
    }

    @IBAction func backspace() {
        if userIsInTheMiddleOfTypingANumber {
            if display.text!.characters.count > 1 {
                display.text = String(dropLast(display.text!.characters))
            } else {
                displayValue = nil
            }
        } else {
            displayValue = brain.undoLast()
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        enter()
        
        if let operation = sender.currentTitle {
            displayValue = brain.performOperation(operation)
        }
    }
    
    @IBAction func enter() {
        if userIsInTheMiddleOfTypingANumber {
            if let currentValue = displayValue {
                brain.pushOperand(currentValue)
            }
            
            displayValue = nil
        }
    }
    
    var displayValue: Double? {
        get {
            let formater = NSNumberFormatter()
            if let parsedNumber = formater.numberFromString(display.text!) {
                return parsedNumber.doubleValue
            } else {
                return nil
            }
        }
        set {
            descriptionDisplay.text = brain.description
            
            if let newDouble = newValue {
                let (integerPart, fractionalPart) = modf(newDouble)
                
                display.text =
                    fractionalPart == 0 ? "\(Int(integerPart))" : "\(newDouble)"
                descriptionDisplay.text = descriptionDisplay.text! + "="
            } else {
                if let errors = brain.evaluateAndReportErrors() {
                    display.text = errors
                } else {
                    display.text = defaultDisplayText
                }
            }
            
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    @IBAction func clear() {
        brain.clear()
        brain.variableValues["M"] = nil
        displayValue = nil
    }
    
    @IBAction func setMemoryVariable() {
        if let currentValue = displayValue {
            brain.variableValues["M"] = currentValue
        }
        
        displayValue = brain.evaluate()
    }
    
    @IBAction func getMemoryVariable() {
        enter()
        brain.pushOperand("M")
        displayValue = brain.evaluate()
    }
    
    private func appendDigit(digit: String) {
        if userIsInTheMiddleOfTypingANumber {
            display.text = display.text! + digit
        } else {
            // replace default 0 with first inputed digit
            display.text = digit
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    private func appendDecimalPoint() {
        if userIsInTheMiddleOfTypingANumber {
            // .. only allow one decimal point to be entered
            if display.text!.rangeOfString(".") == nil {
                display.text = display.text! + "."
            }
        }
            // prepend with 0 if decimal point is the first inputed character
        else {
            display.text = "0."
            userIsInTheMiddleOfTypingANumber = true
        }
    }
    
    private func toggleNegativeSign() {
        if display.text!.rangeOfString("-") == nil {
            display.text = "-" + display.text!
        } else {
            display.text = String(dropFirst(display.text!.characters))
        }
    }
}

