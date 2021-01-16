//
//  CompactMapObservable.swift
//  
//
//  Created by Markus Pfeifer on 14.01.21.
//

import Foundation


public extension Observable {
    
    @inlinable
    func compactMap<NewValue>(_ closure: @escaping (Observation) -> NewValue?) -> CompactMapObservable<Self, NewValue> {
        CompactMapObservable(base: self, cmap: closure)
    }
    
    @inlinable
    func filter(predicate: @escaping (Observation) -> Bool) -> CompactMapObservable<Self, Observation> {
        compactMap{predicate($0) ? $0 : nil}
    }
    
    @inlinable
    func skipNils<T>() -> CompactMapObservable<Self, T> where Observation == T? {
        compactMap{$0}
    }
    
    @inlinable
    func skipErrors<T,E : Error>() -> CompactMapObservable<Self, T> where Observation == Result<T,E> {
        compactMap{try? $0.get()}
    }
    
    @inlinable
    func downcast<D : Downcast>(_ downcast: D) -> CompactMapObservable<Self, D.SubType> where D.SuperType == Observation {
        compactMap{downcast.downCast($0)}
    }
    
}

public extension Observer {
    
    @inlinable
    func contraCompactMap<NewValue>(_ closure: @escaping (NewValue) -> Observation?) -> ContraCompactMapObserver<Self, NewValue> {
        ContraCompactMapObserver(base: self, cmap: closure)
    }
    
    @inlinable
    func guarded(by predicate: @escaping (Observation) -> Bool) -> ContraCompactMapObserver<Self, Observation> {
        contraCompactMap{predicate($0) ? $0 : nil}
    }
    
}


public struct ContraCompactMapObserver<Base : Observer, NewValue> : Observer {
    
    @usableFromInline
    let base : Base
    @usableFromInline
    let cmap : (NewValue) -> Base.Observation?
    
    @usableFromInline
    init(base: Base, cmap: @escaping (NewValue) -> Base.Observation?){
        (self.base, self.cmap) = (base, cmap)
    }
    
    @inlinable
    public func send(_ observation: NewValue) {
        guard let observation = cmap(observation) else {
            return
        }
        base.send(observation)
    }
    
}


public struct CompactMapObservable<Base : Observable, NewValue> : Observable {
    
    public typealias Observation = NewValue
    
    @usableFromInline
    let base : Base
    @usableFromInline
    let cmap : (Base.Observation) -> NewValue?
    
    @usableFromInline
    init(base: Base, cmap: @escaping (Base.Observation) -> NewValue?){
        (self.base, self.cmap) = (base, cmap)
    }
    
    public func subscribe<O>(observer: O) -> Base.Cancellation where O : Observer, NewValue == O.Observation {
        base.subscribe(observer: observer.contraCompactMap(cmap))
    }
    
}
