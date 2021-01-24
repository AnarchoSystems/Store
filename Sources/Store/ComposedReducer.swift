//
//  ComposedReducer.swift
//  
//
//  Created by Markus Pfeifer on 18.12.20.
//

import Foundation

infix operator <> : AdditionPrecedence

public extension DependentReducer {
    
    @inlinable
    static func <><O : DependentReducer>(lhs: Self, rhs: O) -> ComposedReducer<Self, O> where O.Implementation.State == Implementation.State {
        lhs.compose(with: rhs)
    }
    
    @inlinable
    func compose<O : DependentReducer>(with other: O) -> ComposedReducer<Self, O> where O.Implementation.State == Implementation.State {
        ComposedReducer(r1: self, r2: other)
    }
    
}


public struct ComposedReducer<R1 : DependentReducer, R2 : DependentReducer> : DependentReducer where R1.Implementation.State == R2.Implementation.State {
    
    @usableFromInline
    var r1 : R1
    @usableFromInline
    var r2 : R2
    
    @usableFromInline
    init(r1: R1, r2: R2){
        self.r1 = r1
        self.r2 = r2
    }
    
    public func inject(from environment: Dependencies) -> Implementation {
        Implementation(r1: r1.inject(from: environment),
                       r2: r2.inject(from: environment))
    }
    
    public struct Implementation : ReducerImplementation {
        
        @usableFromInline
        var r1 : R1.Implementation
        @usableFromInline
        var r2 : R2.Implementation
        
        @usableFromInline
        init(r1: R1.Implementation, r2: R2.Implementation){
            self.r1 = r1
            self.r2 = r2
        }
        
        
        @inlinable
        public func apply<Action : DynamicAction>(to state: inout R1.Implementation.State,
                                                  action: Action) -> [DynamicEffect] {
            var result = r1.apply(to: &state, action: action)
            result.append(contentsOf: r2.apply(to: &state, action: action))
            return result
        }
        
        
    }
    
}


extension ComposedReducer : ReducerImplementation, IndepentendReducerWrapper where R1 : IndepentendReducerWrapper, R2 : IndepentendReducerWrapper, R1.Body.State == R2.Body.State {
    
    public var body: Body {
        Body(r1: r1.body, r2: r2.body)
    }
    
    public struct Body : ReducerImplementation {
        
        let r1 : R1.Body
        let r2 : R2.Body
        
        public func apply<Action>(to state: inout R1.Body.State, action: Action) -> [DynamicEffect] where Action : DynamicAction {
            r1.apply(to: &state, action: action) + r2.apply(to: &state, action: action)
        }
        
    }
    
}
