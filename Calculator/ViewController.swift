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
    @IBOutlet weak var historyDisplay: UILabel!
    @IBOutlet weak var display: UILabel!
    
    var userIsInTheMiddleOfTypingANumber = false

    @IBAction func appendDigit(sender: UIButton) {
        let value = sender.currentTitle!
        
        if userIsInTheMiddleOfTypingANumber {
            // Add if value is a digit, or the decimal dot is being input the first time
            if (value != ".") || (display.text!.rangeOfString(".") == nil) {
                display.text = display.text! + value
            }
        } else {
            display.text = value == "." ? "0." : value
        }
        
        userIsInTheMiddleOfTypingANumber = true
    }

    @IBAction func backspace() {
        // Only affect numbers manually inputted
        guard userIsInTheMiddleOfTypingANumber else {
            return
        }
        
        guard let currentText = display.text else {
            return
        }
        
        switch currentText.characters.count {
        case 1:
            userIsInTheMiddleOfTypingANumber = false
            display.text = "0"
        case let length where length > 1:
            display.text = currentText.substringToIndex(currentText.endIndex.predecessor())
        default: return
        }
    }
    
    @IBAction func invertSign(sender: UIButton) {
        if userIsInTheMiddleOfTypingANumber {
            if display.text!.rangeOfString("-") == nil {
                display.text = "-" + display.text!
            } else {
                display.text = display.text!.substringFromIndex(display.text!.startIndex.successor())
            }
        } else {
            operate(sender)
        }
    }
    
    @IBAction func operate(sender: UIButton) {
        let operation = sender.currentTitle!
        
        if userIsInTheMiddleOfTypingANumber {
            enter()
        }
        
        switch operation {
        case "×": performOperation(*)
        case "÷": performOperation { $1 / $0 }
        case "+": performOperation { $0 + $1 }
        case "−": performOperation { $1 - $0 }
        case "√": performOperation(sqrt)
        case "sin": performOperation(sin)
        case "cos": performOperation(cos)
        case "π": inputOperand(M_PI)
        case "ᐩ/-": performOperation { -$0 }
        default: break
        }
        
        if let _ = displayValue {
            historyDisplay.text = historyDisplay.text! + " \(operation)"
            enter()
        }
    }
    
    func performOperation(operation: (Double, Double) -> Double) {
        if operandStack.count >= 2 {
            displayValue = operation(operandStack.removeLast(), operandStack.removeLast())
        } else {
            displayValue = nil
        }
    }
    
    private func performOperation(operation: Double -> Double) {
        if operandStack.count >= 1 {
            displayValue = operation(operandStack.removeLast())
        } else {
            displayValue = nil
        }
    }
    
    func inputOperand(operand: Double) {
        displayValue = operand
    }

    var operandStack = Array<Double>()
    
    @IBAction func enter() {
        if let currentValue = displayValue {
            operandStack.append(currentValue)
            historyDisplay.text = historyDisplay.text! + " \(currentValue)"
            print("operandStack = \(operandStack)")
        }
        
        if userIsInTheMiddleOfTypingANumber {
            displayValue = nil
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    var displayValue: Double? {
        get {
            if let parsedNumber = NSNumberFormatter().numberFromString(display.text!) {
                return parsedNumber.doubleValue
            } else {
                return nil
            }
        }
        set {
            if let newDouble = newValue {
                display.text = "\(newDouble)"
            } else {
                display.text = ""
            }
            userIsInTheMiddleOfTypingANumber = false
        }
    }
    
    @IBAction func clear() {
        displayValue = 0
        historyDisplay.text = "History:"
        operandStack = Array<Double>()
    }
}

