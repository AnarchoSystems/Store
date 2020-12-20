//
//  Function.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation



public protocol Function {
    
    associatedtype Input
    associatedtype Output
    
    func callAsFunction(_ input: Input) -> Output
    
}


public extension Function {
    
    @inlinable
    func asClosure() -> Closure<Input, Output> {
        Closure(callAsFunction)
    }
    
    @inlinable
    func compose<O : Function>(with other: O) -> ComposedFunction<Self, O> where Output == O.Input {
        ComposedFunction(f1: self, f2: other)
    }
    
    
}


public struct Closure<Input, Output> : Function {
    
    @usableFromInline
    let closure : (Input) -> Output
    
    @inlinable
    public init(_ closure: @escaping (Input) -> Output) {
        self.closure = closure
    }
    
    @inlinable
    public func callAsFunction(_ input: Input) -> Output {
        closure(input)
    }
    
}


public struct ComposedFunction<F1 : Function, F2 : Function> : Function where F1.Output == F2.Input {
    
    @usableFromInline
    let f1 : F1
    @usableFromInline
    let f2 : F2
    
    @usableFromInline
    init(f1: F1, f2: F2){
        self.f1 = f1
        self.f2 = f2
    }
    
    @inlinable
    public func callAsFunction(_ input: F1.Input) -> F2.Output {
        f2(f1(input))
    }
    
}
