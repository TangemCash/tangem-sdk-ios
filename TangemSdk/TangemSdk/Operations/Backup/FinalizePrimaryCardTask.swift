//
//  FinalizePrimaryCardTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class FinalizePrimaryCardTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }
    
    private let backupCards: [BackupCard]
    private let accessCode: Data
    private let passcode: Data
    private var attestSignature: Data? //We already have attestSignature
    private let onLink: (Data) -> Void
    private let onRead: ((String, [EncryptedBackupData])) -> Void
    private let onFinalize: () -> Void
    private let readBackupStartIndex: Int
    
    init(backupCards: [BackupCard],
         accessCode: Data,
         passcode: Data,
         readBackupStartIndex: Int, //for restore
         attestSignature: Data?,
         onLink: @escaping (Data) -> Void,
         onRead: @escaping ((String,[EncryptedBackupData])) -> Void,
         onFinalize: @escaping () -> Void) {
        self.backupCards = backupCards
        self.accessCode = accessCode
        self.passcode = passcode
        self.attestSignature = attestSignature
        self.onLink = onLink
        self.onRead = onRead
        self.onFinalize = onFinalize
        self.readBackupStartIndex = readBackupStartIndex
    }

    deinit {
        Log.debug("FinalizePrimaryCardTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        guard let backupStatus = card.backupStatus else {
            completion(.failure(.backupFailedFirmware))
            return
        }
        
        let linkAction = getLinkAction(with: backupStatus)
        
        if case .retry = linkAction { //We should swap codes only if they were set on the card.
            if card.isAccessCodeSet {
                session.environment.accessCode = UserCode(.accessCode, value: accessCode)
            }
            
            if card.isPasscodeSet! { //It's safe to force unwrap here
                session.environment.passcode = UserCode(.passcode, value: passcode)
            }
        }
        
        if linkAction != .skip {
            let command = LinkBackupCardsCommand(backupCards: backupCards,
                                                 accessCode: accessCode,
                                                 passcode: passcode)
            
            command.run(in: session) { linkResult in
                switch linkResult {
                case .success(let linkResponse):
                    self.onLink(linkResponse.attestSignature)
                    self.readBackupData(session: session, index: 0, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            self.readBackupData(session: session, index: readBackupStartIndex, completion: completion)
        }
    }
    
    private func readBackupData(session: CardSession, index: Int, completion: @escaping CompletionResult<Card>) {
        if index >= backupCards.count {
            finalizeBackupData(session: session, completion: completion)
            return
        }
        
        let currentBackupCard = backupCards[index]
        let command = ReadBackupDataCommand(backupCardLinkingKey: currentBackupCard.linkingKey, accessCode: accessCode)
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                self.onRead((currentBackupCard.cardId, response.data))
                self.readBackupData(session: session, index: index + 1, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func finalizeBackupData(session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        guard card.firmwareVersion >= .keysImportAvailable else {
            onFinalize()
            completion(.success(card))
            return
        }
        
        var command: FinalizeReadBackupDataCommand? = .init(accessCode: accessCode)
        
        command?.run(in: session) { result in
            switch result {
            case .success:
                self.onFinalize()
                completion(.success(card))
            case .failure(let error):
                // Backup data already finalized, but we didn't catch the original response due to NFC errors or tag lost. Just cover invalid state error
                if case .invalidState = error {
                    Log.debug("Got \(error). Ignoring..")
                    self.onFinalize()
                    completion(.success(card))
                    return
                }

                completion(.failure(error))
            }
            
            command = nil
        }
    }
    
    private func getLinkAction(with status: Card.BackupStatus) -> LinkAction {
        switch status {
        case .cardLinked, .active:
            if attestSignature != nil {
                //We already have attest signature and card already linked. Can skip linking
                return .skip
            } else {
                //We don't have attest signature, but card already linked. Force retry
                // Is this a real case?
                return .retry
            }
        case .noBackup:
            return .link
        }
    }
}

private extension FinalizePrimaryCardTask {
    enum LinkAction {
        case link
        case skip
        case retry
    }
}
