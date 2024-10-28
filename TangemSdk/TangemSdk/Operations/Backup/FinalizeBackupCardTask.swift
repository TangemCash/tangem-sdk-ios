//
//  FinalizeBackupCardTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

class FinalizeBackupCardTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }
    
    private let primaryCard: PrimaryCard
    private let backupCards: [BackupCard]
    private let backupData: [EncryptedBackupData]
    private let attestSignature: Data
    private let accessCode: Data
    private let passcode: Data
    private var commandsBag: [Any]  = .init()
    
    init(primaryCard: PrimaryCard,
         backupCards: [BackupCard],
         backupData: [EncryptedBackupData],
         attestSignature: Data,
         accessCode: Data,
         passcode: Data) {
        self.primaryCard = primaryCard
        self.backupCards = backupCards
        self.backupData = backupData
        self.attestSignature = attestSignature
        self.accessCode = accessCode
        self.passcode = passcode
    }
    
    deinit {
        Log.debug("FinalizeBackupCardTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        switch card.backupStatus {
        case .noBackup: // The direct case
            let command = LinkPrimaryCardCommand(primaryCard: primaryCard,
                                                 backupCards: backupCards,
                                                 attestSignature: attestSignature,
                                                 accessCode: accessCode,
                                                 passcode: passcode)

            command.run(in: session) { linkResult in
                switch linkResult {
                case .success:
                    self.writeBackupData(in: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .active: // Inconsistence case. The card status is ok, but sdk status is incompleted. We should check all wallets later on the app side.
            readWallets(in: session, completion: completion)
        default: // only an interrupted case is possible
            writeBackupData(in: session, completion: completion)
        }
    }
    
    private func writeBackupData(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let writeCommand = WriteBackupDataCommand(backupData: self.backupData,
                                                  accessCode: self.accessCode)
        self.commandsBag.append(writeCommand)
        
        writeCommand.run(in: session) { writeResult in
            switch writeResult {
            case .success(let writeResponse):
                if writeResponse.backupStatus == .active {
                    self.readWallets(in: session, completion: completion)
                } else {
                    completion(.failure(TangemSdkError.unknownError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readWallets(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        ReadWalletsListCommand().run(in: session) { result in
            switch result {
            case .success:
                completion(.success(session.environment.card!))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
