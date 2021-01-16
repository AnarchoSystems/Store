//
//  Observable.swift
//  
//
//  Created by Markus Pfeifer on 11.01.21.
//

import Foundation

public protocol Cancellable {
    func cancel()
}

public extension Cancellable {
    func callAsFunction(){
        cancel()
    }
}

public class ClosureCancellable : Cancellable {
    @usableFromInline
    let closure : () -> Void
    @usableFromInline
    let lock = NSLock()
    
    fileprivate init(closure: @escaping () -> Void) {
        self.closure = closure
    }
    @inlinable
    public func cancel() {
        lock.lock()
        closure()
        lock.unlock()
    }
    deinit {
        cancel()
    }
}

public struct NopCancellation : Cancellable {
    @inlinable
    public func cancel(){}
}

public typealias AnyCancellable = ClosureCancellable

public extension Cancellable {
    
    func erased() -> AnyCancellable {
        ClosureCancellable(closure: cancel)
    }
    
}

public class CombinedCancellable : Cancellable {
    let lock = NSLock()
    let list : [Cancellable]
    init(list: [Cancellable]){
        self.list = list
    }
    public func cancel() {
        lock.lock()
        for c in list {
            c()
        }
        lock.unlock()
    }
}

public enum Cancellables {
    public static func create(_ closure: @escaping () -> Void) -> ClosureCancellable {
        ClosureCancellable(closure: closure)
    }
    public static func nop() -> NopCancellation {
        NopCancellation() 
    }
    public static func many(_ list: Cancellable...) -> CombinedCancellable {
        CombinedCancellable(list: list)
    }
    public static func many(_ list: [Cancellable]) -> CombinedCancellable {
        CombinedCancellable(list: list)
    }
}

public protocol Observer {
    associatedtype Observation
    func send(_ observation: Observation)
}

public protocol Observable {
    
    associatedtype Observation
    associatedtype Cancellation : Cancellable
    
    func subscribe<O : Observer>(observer: O) -> Cancellation where O.Observation == Observation
    
    func subscribe(closure: @escaping (Observation) -> Void) -> Cancellation
    
}

public extension Observable {
    
    @inlinable
    func subscribe(closure: @escaping (Observation) -> Void) -> Cancellation {
        subscribe(observer: ClosureObserver(closure))
    }
    
}


@usableFromInline
struct ClosureObserver<T> : Observer {
    
    @usableFromInline
    let closure : (T) -> Void
    
    @usableFromInline
    init(_ closure: @escaping (T) -> Void) {self.closure = closure}
    
    @usableFromInline
    func send(_ observation: T) {
        closure(observation)
    }
    
}


public extension Observable {
    
    @inlinable
    func bind<Ob : AnyObject>(_ object: Ob,
                              selector: @escaping (Ob) -> (Observation) -> Void) -> some Cancellable {
        let observer = BindingObserver<Ob,Observation,Cancellation>(
            base: object,
            selector: selector
        )
        observer.cancel = subscribe(observer: observer)
        return observer.cancel
    }
    
    @inlinable
    func bind<Ob : AnyObject>(_ object: Ob,
                                       property: ReferenceWritableKeyPath<Ob,Observation>) -> some Cancellable {
        let observer = BindingObserver<Ob,Observation,Cancellation>(
            base: object)
        {obj in
            {newValue in
                obj[keyPath: property] = newValue
            }
        }
        observer.cancel = subscribe(observer: observer)
        return observer.cancel
    }
    
}

@usableFromInline
final class BindingObserver<Base : AnyObject, T, C: Cancellable> : Observer {
    
    weak var base : Base?
    @usableFromInline
    var cancel : C!
    let selector : (Base) -> (T) -> Void
    
    @usableFromInline
    init(base: Base,
         selector: @escaping (Base) -> (T) -> Void) {
        self.base = base
        self.selector = selector
    }
    
    @usableFromInline
    func send(_ observation: T) {
        guard let base = base else {
            return cancel()
        }
        selector(base)(observation)
    }
    
    deinit {
        cancel()
    }
    
}
