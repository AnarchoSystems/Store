//
//  ObservableErasures.swift
//  
//
//  Created by Markus Pfeifer on 13.01.21.
//

import Foundation


public extension Observable {
    
    @inlinable
    func erased() -> AnyObservable<Observation> {
        AnyObservable(base: self)
    }
    
}

public struct ObservableCast<O : Observable> : Embedding {
    
    @inlinable
    public init(type: O.Type = O.self) {}
    
    @inlinable
    public func cast(_ object: O) -> AnyObservable<O.Observation> {
        object.erased()
    }
    
    @inlinable
    public func downCast(_ object: AnyObservable<O.Observation>) -> O? {
        (object.base as? _ConcreteObservable<O>)?.base
    }
    
}


public struct AnyObservable<T> : Observable {
    
    @usableFromInline
    let base : _AnyObservable<T>
    
    @usableFromInline
    init<Base : Observable>(base: Base) where Base.Observation == T {
        self.base = _ConcreteObservable(base: base)
    }
    
    @inlinable
    public func subscribe<O>(observer: O) -> ClosureCancellable where T == O.Observation, O : Observer {
        base.subscribe(observer: observer)
    }
    
    @inlinable
    public func subscribe(closure: @escaping (T) -> Void) -> ClosureCancellable {
        base.subscribe(closure: closure)
    }
    
}

@usableFromInline
class _AnyObservable<T> : Observable {
    
    @usableFromInline
    func subscribe<O>(observer: O) -> ClosureCancellable where O : Observer, T == O.Observation {
        fatalError("abstract")
    }
    
    @usableFromInline
    func subscribe(closure: @escaping (T) -> Void) -> ClosureCancellable {
        fatalError("abstract")
    }
    
}

@usableFromInline
final class _ConcreteObservable<Base : Observable> : _AnyObservable<Base.Observation> {
    
    @usableFromInline
    let base : Base
    
    @usableFromInline
    init(base: Base){self.base = base}
    
    @usableFromInline
    override func subscribe<O>(observer: O) -> ClosureCancellable where Base.Observation == O.Observation, O : Observer {
        let cancel = base.subscribe(observer: observer)
        return Cancellables.create(cancel.cancel)
    }
    
    @usableFromInline
    override func subscribe(closure: @escaping (Base.Observation) -> Void) -> ClosureCancellable {
        let cancel = base.subscribe(closure: closure)
        return Cancellables.create(cancel.cancel)
    }
    
}

public extension Observer {
    
    @inlinable
    func erased() -> AnyObserver<Observation> {
        AnyObserver(base: self)
    }
    
}

public struct ObserverCast<O : Observer> : Embedding {
    
    @inlinable
    public init(type: O.Type = O.self) {}
    
    @inlinable
    public func cast(_ object: O) -> AnyObserver<O.Observation> {
        object.erased()
    }
    
    @inlinable
    public func downCast(_ object: AnyObserver<O.Observation>) -> O? {
        (object.base as? _ConcreteObserver<O>)?.base
    }
    
}

public struct AnyObserver<T> : Observer {
    
    @usableFromInline
    let base : _AnyObserver<T>
    
    @usableFromInline
    init<Base : Observer>(base: Base) where Base.Observation == T {
        self.base = _ConcreteObserver(base: base)
    }
    
    @inlinable
    public func send(_ observation: T) {
        base.send(observation)
    }
    
}


@usableFromInline
class _AnyObserver<T> : Observer {
    
    @usableFromInline
    func send(_ observation: T) {
        fatalError("abstract")
    }
    
}

@usableFromInline
final class _ConcreteObserver<Base : Observer> : _AnyObserver<Base.Observation> {
    
    @usableFromInline
    let base : Base
    
    init(base: Base){self.base = base}
    
    @usableFromInline
    override func send(_ observation: Base.Observation) {
        base.send(observation)
    }
    
}


public struct ClosureObservable<T> : Observable {
    
    @usableFromInline
    let closure : (AnyObserver<T>) -> ClosureCancellable
    
    @inlinable
    public init<C : Cancellable>(_ closure: @escaping (AnyObserver<T>) -> C) {
        self.closure = {ob in
            let c = closure(ob)
            return Cancellables.create(c.cancel)
        }
    }
    
    @inlinable
    public init<C : Cancellable>(_ closure: @escaping (@escaping (T) -> Void) -> C) {
        self.closure = {ob in
            let c = closure(ob.send)
            return Cancellables.create(c.cancel)
        }
    }
    
    @inlinable
    public func subscribe<O>(observer: O) -> ClosureCancellable where O : Observer, T == O.Observation {
        closure(observer.erased())
    }
    
    @inlinable
    public func subscribe(closure: @escaping (T) -> Void) -> ClosureCancellable {
        self.closure(ClosureObserver(closure).erased())
    }
    
}


public enum Observables {
    
    @inlinable
    public static func withClosureObserver<T,C : Cancellable>(_ closure: @escaping (@escaping (T) -> Void) -> C) -> ClosureObservable<T> {
        ClosureObservable(closure)
    }
    
    @inlinable
    public static func create<T,C : Cancellable>(_ closure: @escaping (AnyObserver<T>) -> C) -> ClosureObservable<T> {
        ClosureObservable(closure)
    }
    
}
