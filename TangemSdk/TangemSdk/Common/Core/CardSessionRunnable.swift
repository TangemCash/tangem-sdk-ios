//
//  CardSessionRunnable.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Base protocol for run tasks in a card session
public protocol CardSessionRunnable {
    /// Mode for preflight read. Change this property only if you understand what to do
    var preflightReadMode: PreflightReadMode { get }
    
    /// Allow SDK to fetch access code from the local encrypted repository when running the command
    var shouldAskForAccessCode: Bool { get }

    /// An enforced encryption mode. Managed by a card if none. None by default.
    var encryptionMode: EncryptionMode { get }

    /// Simple interface for responses received after sending commands to Tangem cards.
    associatedtype Response
    
    /// This method will be called before nfc session starts.
    /// - Parameters:
    ///   - session:You can use view delegate methods at this moment, but not commands execution
    ///   - completion: Call the completion handler to complete the task.
    func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>)
    
    /// The starting point for custom business logic. Adopt this protocol and use `TangemSdk.startSession` to run
    /// - Parameters:
    ///   - session: You can run commands in this session
    ///   - completion: Call the completion handler to complete the task.
    func run(in session: CardSession, completion: @escaping CompletionResult<Response>)
}

extension CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .fullCardRead }
    
    public var shouldAskForAccessCode: Bool { true }

    public var encryptionMode: EncryptionMode { .none }

    public func prepare(_ session: CardSession, completion: @escaping CompletionResult<Void>) {
        completion(.success(()))
    }
}

extension CardSessionRunnable where Response: JSONStringConvertible {
    public func eraseToAnyRunnable() -> AnyJSONRPCRunnable {
        AnyJSONRPCRunnable(self)
    }
}
