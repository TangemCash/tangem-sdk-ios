//
//  ResetPinTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class ResetPinTask: CardSessionRunnable {
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let confirmationCard: ConfirmationCard
    private let accessCode: Data
    private let passcode: Data
    
    private var commandsBag: [Any]  = .init()
    
    init(confirmationCard: ConfirmationCard, accessCode: Data, passcode: Data) {
        self.confirmationCard = confirmationCard
        self.accessCode = accessCode
        self.passcode = passcode
    }
    
    deinit {
        Log.debug("ResetPinTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<SuccessResponse>) {
        let prepareCommand = AuthorizeResetPinTokenCommand(confirmationCard: confirmationCard)
        prepareCommand.run(in: session) { result in
            switch result {
            case .success:
                let resetCommand = ResetPinCommand(accessCode: self.accessCode, passcode: self.passcode)
                self.commandsBag.append(resetCommand)
                resetCommand.run(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
