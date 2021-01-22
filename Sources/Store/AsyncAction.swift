//
//  AsyncAction.swift
//  
//
//  Created by Markus Pfeifer on 20.01.21.
//

import Foundation

public struct FailedAsyncAction : DynamicAction {
    public let kind : Any.Type
    public let error : Error
}

fileprivate protocol Schedulable : DynamicEffect {
    func schedule<Store : StoreProtocol>(queue: DispatchQueue,
                                         store: Store)
}

public struct AsyncAction<Action : DynamicAction> : Schedulable {
    
    @usableFromInline
    let closure : (DispatchQueue, @escaping (Result<Action, Error>) -> Void) -> Void
    
    fileprivate func schedule<Store : StoreProtocol>(
        queue: DispatchQueue,
        store: Store)
    {
        queue.async {
            closure(queue){result in
                switch result {
                case .success(let action):
                    store.dispatch(action)
                case .failure(let error):
                    store.dispatch(FailedAsyncAction(kind: Action.self,
                                                     error: error))
                }
            }
        }
    }
    
}

public extension AsyncAction {
    
    init(_ closure: @escaping () throws -> Action) {
        self = AsyncAction.withUnsafeContinuation{handler in
            do {
                try handler(.success(closure()))
            }
            catch {
                handler(.failure(error))
            }
        }
    }
    
    static func withUnsafeContinuation(
        _ closure: @escaping (@escaping (Result<Action,Error>) -> Void) -> Void
    ) -> AsyncAction {
        AsyncAction{queue, handler in
            closure{result in
                queue.async {
                    handler(result)
                }
            }
        }
    }
    
    func map<T : DynamicAction>(_ transform: @escaping (Action) -> T) -> AsyncAction<T> {
        AsyncAction<T>{queue, handler in
            closure(queue){result in
                handler(result.map(transform))
            }
        }
    }
    
    func flatMap<T : DynamicAction>(_ transform: @escaping (Action) -> AsyncAction<T>) -> AsyncAction<T> {
        AsyncAction<T>{queue, handler in
            closure(queue){result in
                switch result.map(transform) {
                case .success(let promise):
                    promise.closure(queue, handler)
                case .failure(let error):
                    handler(.failure(error))
                }
            }
        }
    }
    
}


public func zip<A : DynamicAction, B : DynamicAction, C : DynamicAction>(
    _ async1 : AsyncAction<A>,
    _ async2 : AsyncAction<B>,
    combine: @escaping (A,B) -> C
) -> AsyncAction<C> {
    
    AsyncAction<C>{queue, handler in
        
        var a : Result<A,Error>?
        var b : Result<B,Error>?
        
        let serial = DispatchQueue(label: "Serial")
        
        let callback : () -> Void = {
            serial.async{
                guard let a = a, let b = b else {
                    return
                }
                handler(a.flatMap{a in b.map{b in combine(a,b)}})
            }
        }
        
        async1.closure(queue){x in
            a = x
            callback()
        }
        
        async2.closure(queue){x in
            b = x
            callback()
        }
        
    }
    
}

func zip<T : DynamicAction, U : DynamicAction>(_ actions: [AsyncAction<T>],
                                               combine: @escaping ([T]) -> U) -> AsyncAction<U> {
    
    AsyncAction{queue, handler in
        
        var result = [T?](repeating: nil, count: actions.count)
        var completed = 0
        
        let serial = DispatchQueue(label: "Serial")
        
        let callback : (Result<T,Error>, Int) -> Void = {x, int in
            serial.async {
                switch x {
                case .success(let t):
                    result[int] = t
                    completed += 1
                    if completed == actions.count {
                        handler(.success(combine(result as! [T])))
                    }
                case .failure(let err):
                    completed = actions.count + 1
                    handler(.failure(err))
                }
            }
        }
        
        for (idx, action) in actions.enumerated() {
            action.closure(queue){result in
                callback(result, idx)
            }
        }
        
    }
    
}



public struct AsyncMiddleware<BaseDispatch : DispatchFunction, State> : Middleware {
    
    let queue : DispatchQueue
    
    public init(queue: DispatchQueue = DispatchQueue.global()) {
        self.queue = queue
    }
    
    public func apply(to dispatchFunction: BaseDispatch,
                      store: StoreStub<State>,
                      environment: Dependencies) -> NewDispatch {
        NewDispatch(base: dispatchFunction,
                    store: store,
                    queue: queue)
    }
    
    public struct NewDispatch : DispatchFunction {
        
        var base : BaseDispatch
        let store : StoreStub<State>
        let queue : DispatchQueue
        
        public mutating func dispatch<Action : DynamicAction>(_ action: Action) -> [DynamicEffect] {
            
            let result = base.dispatch(action)
            
            for action in result {
                if let action = action as? Schedulable {
                    action.schedule(queue: queue, store: store)
                }
            }
            
            return result
            
        }
        
    }
    
}
