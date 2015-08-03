//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Emil Culic on 30/07/2015.
//  Copyright © 2015 Emil Culic. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    private enum Op: CustomStringConvertible
    {
        case Operand(Double)
        case Variable(String)
        case Constant(String, Double)
        case UnaryOperation(String, Double -> Double, (Double -> String?)?)
        case BinaryOperation(String, (Double, Double) -> Double, ((Double, Double) -> String?)?)
        
        var description: String {
            get {
                switch self {
                case .Operand(let operand):
                    return "\(operand)"
                case .Variable(let symbol):
                    return symbol
                case .Constant(let symbol, _):
                    return symbol
                case .UnaryOperation(let symbol, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _):
                    return symbol
                }
            }
        }
        
        var precedence: Int {
            get {
                switch self {
                case .BinaryOperation(let symbol, _, _):
                    switch symbol {
                    case "+", "-": return 0
                    case "×", "÷": return 1
                    default: return Int.max
                    }
                default:
                    return Int.max
                }
            }
        }
    }
    
    private var opStack = [Op]()
    
    private var knownOps = [String:Op]()
    
    var variableValues: Dictionary<String,Double>
    
    init() {
        variableValues = [:]
        
        func learnOp(op: Op) {
            knownOps[op.description] = op
        }
        
        learnOp(Op.BinaryOperation("×", *, nil))
        learnOp(Op.BinaryOperation("÷", { $1 / $0 },
            { denominator, _ in denominator == 0 ? "Division by zero" : nil }))
        learnOp(Op.BinaryOperation("+", +, nil))
        learnOp(Op.BinaryOperation("−", { $1 - $0 }, nil))
        learnOp(Op.UnaryOperation("√", sqrt,
            { $0 < 0 ? "Square root not defined for negative numbers" : nil}))
        learnOp(Op.UnaryOperation("sin", sin, nil))
        learnOp(Op.UnaryOperation("cos", cos, nil))
        learnOp(Op.UnaryOperation("ᐩ/-", -, nil))
        learnOp(Op.Constant("π", M_PI))
    }
    
    var program: AnyObject { // guaranteed to be a PropertyList
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? Array<String> {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownOps[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter()
                        .numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    func evaluate() -> Double? {
        let (result, errors, remainder) = evaluateAndReturnErrors(opStack)
        print("\(opStack) = \(result) with \(remainder) left over, errors: \(errors)")
        return result
    }
    
    private func evaluateAndReturnErrors(ops: [Op]) -> (result: Double?, errors: String?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
            case .Operand(let operand):
                return (operand, nil, remainingOps)
            case .Variable(let symbol):
                if let variableValue = variableValues[symbol] {
                    return (variableValue, nil, remainingOps)
                } else {
                    return (nil, "variable \(symbol) not set yet", ops)
                }
            case .Constant(_, let value):
                return (value, nil, remainingOps)
            case .UnaryOperation(_, let operation, let errorTest):
                let operandEvaluation = evaluateAndReturnErrors(remainingOps)
                
                if let operand = operandEvaluation.result {
                    if let failureDescription = errorTest?(operand) {
                        return (nil, failureDescription, ops)
                    } else {
                        return (operation(operand), nil, operandEvaluation.remainingOps)
                    }
                } else if let _ = operandEvaluation.errors {
                    return operandEvaluation
                } else {
                    return (nil, "not enough operands", ops)
                }
            case .BinaryOperation(_, let operation, let errorTest):
                let op1Evaluation = evaluateAndReturnErrors(remainingOps)
                
                if let op1 = op1Evaluation.result {
                    let op2Evaluation = evaluateAndReturnErrors(op1Evaluation.remainingOps)
                    
                    if let op2 = op2Evaluation.result {
                        if let failureDescription = errorTest?(op1, op2) {
                            return (nil, failureDescription, ops)
                        } else {
                            return (operation(op1, op2), nil, op2Evaluation.remainingOps)
                        }
                    } else if let _ = op2Evaluation.errors {
                        return op2Evaluation
                    } else {
                        return (nil, "not enough operands", ops)
                    }
                } else if let _ = op1Evaluation.errors {
                    return op1Evaluation
                } else {
                    return (nil, "not enough operands", ops)
                }
            }
        }
        
        return (nil, nil, ops)
    }
    
    func evaluateAndReportErrors() -> String? {
        return evaluateAndReturnErrors(opStack).errors
    }
    
    var description: String {
        get {
            if opStack.isEmpty {
                return ""
            }
            
            var tempDescription = description(opStack)
            var fullResult = tempDescription.result
            
            while !tempDescription.remainingOps.isEmpty {
                tempDescription = description(tempDescription.remainingOps)
                fullResult = "\(tempDescription.result), " + fullResult
            }

            return fullResult
        }
    }

    private func description(ops: [Op]) -> (result: String, remainingOps: [Op])
    {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
            case .Operand(let operand):
                return ("\(operand)", remainingOps)
            case .Variable(let symbol):
                return(symbol, remainingOps)
            case .Constant(let symbol, _):
                return (symbol, remainingOps)
            case .UnaryOperation(let symbol, _, _):
                let opDescription = description(remainingOps)
                
                return
                    ("\(symbol)(\(opDescription.result))",
                        opDescription.remainingOps)
            case .BinaryOperation(let symbol, _, _):
                var op1Desc = description(remainingOps)
                var op2Desc = description(op1Desc.remainingOps)

                // Add necessary parentheses
                if let leftOp = op1Desc.remainingOps.last {
                    if leftOp.precedence < op.precedence {
                        op2Desc.result = "(\(op2Desc.result))"
                    }
                }
                if let rightOp = remainingOps.last {
                    if rightOp.precedence < op.precedence {
                        op1Desc.result = "(\(op1Desc.result))"
                    }
                }

                return ("\(op2Desc.result) \(symbol) \(op1Desc.result)",
                    op2Desc.remainingOps)
            }
        }
        
        return ("?", ops)
    }
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        
        return evaluate()
    }
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        
        return evaluate()
    }
    
    func performOperation(symbol: String) -> Double? {
        if let operation = knownOps[symbol] {
            opStack.append(operation)
        }
        
        return evaluate()   
    }
    
    func undoLast() -> Double? {
        guard !opStack.isEmpty else {
            return evaluate()
        }
        
        opStack.removeLast()
        return evaluate()
    }
    
    func clear() {
        opStack = [Op]()
    }
}