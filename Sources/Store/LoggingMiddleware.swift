//
//  LoggingMiddleware.swift
//  
//
//  Created by Markus Pfeifer on 01.01.21.
//

import Foundation


public protocol Logger {
    func log(action: DynamicAction, effect: [DynamicEffect])
}


public struct LoggingMiddleware<State, Base : DispatchFunction, L : Logger> : Middleware {
    
    @usableFromInline
    let logger : L
    
    @inlinable
    public init(logger: L) {
        self.logger = logger
    }
    
    @inlinable
    public func apply(to dispatchFunction: Base,
                      store: StoreStub<State>,
                      environment: Environment) -> NewDispatch {
        NewDispatch(logger: logger, base: dispatchFunction)
    }
    
    public struct NewDispatch : DispatchFunction {
        
        @usableFromInline
        let logger : L
        @usableFromInline
        var base : Base
        
        @usableFromInline
        init(logger: L, base: Base){
            self.logger = logger
            self.base = base
        }
        
        @inlinable
        mutating public func dispatch(_ action: DynamicAction) -> [DynamicEffect] {
            
            let eff = base.dispatch(action)
            logger.log(action: action, effect: eff)
            return eff
            
        }
        
    }
    
}
