//
//  SetUserCodeRecoveryAllowedTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public final class SetUserCodeRecoveryAllowedTask: CardSessionRunnable {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let isAllowed: Bool
    
    /// Default initializer
    /// - Parameter isAllowed: Is this card can reset user codes on the other linked card or not
    public init(isAllowed: Bool) {
        self.isAllowed = isAllowed
    }
    
    deinit {
        Log.debug("SetUserCodeRecoveryAllowedTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        var userSettings = card.userSettings
        userSettings.isUserCodeRecoveryAllowed = isAllowed
        
        let setUserSettingsCommand = SetUserSettingsCommand(settings: userSettings)
        setUserSettingsCommand.run(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(SuccessResponse(cardId: response.cardId)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
