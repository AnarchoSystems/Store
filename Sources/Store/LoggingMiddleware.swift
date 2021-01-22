//
//  LoggingMiddleware.swift
//  
//
//  Created by Markus Pfeifer on 01.01.21.
//

import Foundation


public protocol Logger {
    mutating func log(action: DynamicAction,
                      effect: [DynamicEffect])
}

public struct ReplayLogger : Logger {
    
    private(set) public var actions = [DynamicAction]()
    private(set) public var effects = [DynamicEffect]()
    
    public init(){}
    
    public mutating func log(action: DynamicAction,
                             effect: [DynamicEffect]) {
        actions.append(action)
        effects.append(contentsOf: effect)
    }
    
}

public struct Log<State, Base : DispatchFunction, L : Logger> : Middleware {
    
    @usableFromInline
    let logger : L
    
    @inlinable
    public init(logger: L) {
        self.logger = logger
    }
    
    @inlinable
    public func apply(to dispatchFunction: Base,
                      store: StoreStub<State>,
                      environment: Dependencies) -> NewDispatch {
        NewDispatch(logger: logger, base: dispatchFunction)
    }
    
    public struct NewDispatch : DispatchFunction {
        
        @usableFromInline
        var logger : L
        @usableFromInline
        var base : Base
        
        @usableFromInline
        init(logger: L, base: Base){
            self.logger = logger
            self.base = base
        }
        
        @inlinable
        mutating public func dispatch<Action : DynamicAction>(_ action: Action) -> [DynamicEffect] {
            
            let eff = base.dispatch(action)
            logger.log(action: action, effect: eff)
            return eff
            
        }
        
    }
    
}
