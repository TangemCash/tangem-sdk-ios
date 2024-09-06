//
//  AnyRunnable.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 17.05.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Type erased CardSessionRunnable which Response conforms  to JSONStringConvertible
public class AnyJSONRPCRunnable: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode = .fullCardRead
    /// Request Id
    public var id: Int? = nil
    
    private let runClosure: (_ session: CardSession, _ completion: @escaping CompletionResult<AnyJSONRPCResponse>) -> Void
    private let prepareClosure: (_ session: CardSession, _ completion: @escaping CompletionResult<Void>) -> Void

    init<T: CardSessionRunnable>(_ runnable: T) where T.Response : JSONStringConvertible {
        preflightReadMode = runnable.preflightReadMode
        
        prepareClosure = { session, completion in
            runnable.prepare(session, completion: completion)
        }
        
        runClosure = { session, completion in
            runnable.run(in: session) { res in
                switch res {
                case .success(let response):
                    completion(.success(AnyJSONRPCResponse(response)))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
    }
    deinit {
        Log.debug("AnyJSONRPCRunnable deinit")
    }
    
    public func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        prepareClosure(session, completion)
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<AnyJSONRPCResponse>) {
        runClosure(session, completion)
    }
}

public struct AnyJSONRPCResponse: JSONStringConvertible {
    let response: JSONStringConvertible
    
    public init<T: JSONStringConvertible>(_ response: T) {
        self.response = response
    }
    
    public func encode(to encoder: Encoder) throws {
        try response.encode(to: encoder)
    }
}
