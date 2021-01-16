//
//  Variable.swift
//  
//
//  Created by Markus Pfeifer on 14.01.21.
//

import Foundation


@propertyWrapper
open class ObservedValue<Observation> : Observable {
    
    @usableFromInline
    let lock = NSRecursiveLock()
    @usableFromInline
    var subs = [UUID : AnyObserver<Observation>](){
        didSet {
            subsCount = subs.count
        }
    }
    @usableFromInline
    var subsCount : Int = 0{
        didSet {
            onSubscribersCountChange(oldCount: oldValue,
                                     newCount: subsCount)
        }
    }
    
    private(set) public var value : Observation{
        didSet {
            notifyAll()
        }
    }
    
    @inlinable
    open var wrappedValue : Observation {
        value
    }
    
    @inlinable
    open var projectedValue : ObservedValue {
        self
    }
    
    public init(_ value: Observation){
        self.value = value
    }
    
    
    open func subscribe<O>(observer: O) -> Cancellation where O : Observer, Observation == O.Observation {
        lock.lock()
        defer {
            lock.unlock()
        }
        let id = UUID()
        subs[id] = observer.erased()
        return Cancellation(instance: self, uuid: id)
    }
    
    open func mutate(_ change: (inout Observation) -> Void) {
        lock.lock()
        defer {
            lock.unlock()
        }
        change(&value)
    }
    
    private func notifyAll() {
        lock.lock()
        defer {
            lock.unlock()
        }
        for observer in subs.values {
            observer.send(value)
        }
    }
    
    public struct Cancellation : Cancellable {
        
        let instance : ObservedValue
        let uuid : UUID
        
        public func cancel() {
            instance.lock.lock()
            instance.subs.removeValue(forKey: uuid)
            instance.lock.unlock()
        }
        
    }
    
    open func onSubscribersCountChange(oldCount: Int,
                                       newCount: Int) {
        
    }
    
}


@propertyWrapper
public final class Variable<Observation> : ObservedValue<Observation> {
    
    public final override var wrappedValue: Observation{
        value
    }
    
    public final override var projectedValue: Variable<Observation>{
        self
    }
    
}
