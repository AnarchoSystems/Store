//
//  MapObservables.swift
//  
//
//  Created by Markus Pfeifer on 13.01.21.
//

import Foundation



public extension Observer {
    func contraMap<NewValue>(_ closure: @escaping (NewValue) -> Observation) -> ContramapObserver<Self, NewValue> {
        ContramapObserver(base: self, closure: closure)
    }
}

public extension Observable {
    func map<NewValue>(_ closure: @escaping (Observation) -> NewValue) -> MappedObservable<Self,NewValue> {
        MappedObservable(base: self, closure: closure)
    }
    func map<NewValue>(_ closure: @escaping (Observation) throws -> NewValue) -> MappedObservable<Self,Result<NewValue,Error>> {
        MappedObservable(base: self){obs in
            do {
                return try .success(closure(obs))
            }
            catch {
                return .failure(error)
            }
        }
    }
}

public struct ContramapObserver<Base : Observer, NewValue> : Observer {
    @usableFromInline
    let base : Base
    @usableFromInline
    let closure : (NewValue) -> Base.Observation
    public func send(_ observation: NewValue) {
        base.send(closure(observation))
    }
}

public struct MappedObservable<Base : Observable, NewValue> : Observable {
    public typealias Observation = NewValue
    @usableFromInline
    let base : Base
    @usableFromInline
    let closure : (Base.Observation) -> NewValue
    public func subscribe<O>(observer: O) -> Base.Cancellation where O : Observer, NewValue == O.Observation {
        base.subscribe(observer: observer.contraMap(closure))
    }
}
