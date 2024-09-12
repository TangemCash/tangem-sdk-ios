//
//  DepersonalizeCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct DepersonalizeResponse: JSONStringConvertible {
    let success: Bool
}

/**
* Command available on SDK cards only
* This command resets card to initial state,
* erasing all data written during personalization and usage.
*/
public class DepersonalizeCommand: Command {
    public var preflightReadMode: PreflightReadMode { .none }
    
    public init() {}
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<DepersonalizeResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                if response.success {
                    session.environment.accessCode = UserCode(.accessCode, value: nil)
                    session.environment.passcode = UserCode(.passcode, value: nil)
                }
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        return CommandApdu(.depersonalize, tlv: Data())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> DepersonalizeResponse {
        return DepersonalizeResponse(success: true)
    }
}
