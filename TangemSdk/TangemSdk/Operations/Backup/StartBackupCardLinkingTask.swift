//
//  StartBackupCardLinkingTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Response from the Tangem card after `StartBackupCardLinkingTask
struct StartBackupCardLinkingTaskResponse: JSONStringConvertible {
    /// Backup data frrom the card
    let backupCard: BackupCard

    /// Card being added
    let card: Card
}

final class StartBackupCardLinkingTask: CardSessionRunnable {
    var shouldAskForAccessCode: Bool { false }

    private let primaryCard: PrimaryCard
    private let addedBackupCards: [String]
    private let skipCompatibilityChecks: Bool

    init(primaryCard: PrimaryCard, addedBackupCards: [String], skipCompatibilityChecks: Bool = false) {
        self.primaryCard = primaryCard
        self.addedBackupCards = addedBackupCards
        self.skipCompatibilityChecks = skipCompatibilityChecks
    }

    deinit {
        Log.debug("StartBackupCardLinkingTask deinit")
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<StartBackupCardLinkingTaskResponse>) {
        if session.environment.config.handleErrors {
            guard let card = session.environment.card else {
                completion(.failure(.missingPreflightRead))
                return
            }

            let primaryWalletCurves = Set(primaryCard.walletCurves)
            let backupCardSupportedCurves = Set(card.supportedCurves)

            if !skipCompatibilityChecks {
                if card.issuer.publicKey != primaryCard.issuer.publicKey {
                    completion(.failure(.backupFailedWrongIssuer))
                    return
                }

                if card.settings.isHDWalletAllowed != primaryCard.isHDWalletAllowed {
                    completion(.failure(.backupFailedHDWalletSettings))
                    return
                }

                if !isBatchIdCompatible(card.batchId) {
                    completion(.failure(.backupFailedIncompatibleBatch))
                    return
                }

                if let firmwareVersion = primaryCard.firmwareVersion, firmwareVersion != card.firmwareVersion {
                    completion(.failure(.backupFailedIncompatibleFirmware))
                    return
                }
            }

            if let isKeysImportAllowed = primaryCard.isKeysImportAllowed, isKeysImportAllowed != card.settings.isKeysImportAllowed {
                completion(.failure(.backupFailedKeysImportSettings))
                return
            }

            if !primaryWalletCurves.isSubset(of: backupCardSupportedCurves) {
                completion(.failure(.backupFailedNotEnoughCurves))
                return
            }

            if primaryCard.existingWalletsCount > card.settings.maxWalletsCount {
                completion(.failure(.backupFailedNotEnoughWallets))
                return
            }

            if card.cardId.lowercased() == primaryCard.cardId.lowercased() {
                completion(.failure(.backupCardRequired))
                return
            }

            if addedBackupCards.contains(card.cardId) {
                completion(.failure(.backupCardAlreadyAdded))
                return
            }
        }

        let linkingCommand = StartBackupCardLinkingCommand(primaryCardLinkingKey: primaryCard.linkingKey)
        linkingCommand.run(in: session) { result in
            switch result {
            case .success(let backupCard):
                guard let card = session.environment.card else {
                    completion(.failure(.missingPreflightRead))
                    return
                }

                let response = StartBackupCardLinkingTaskResponse(backupCard: backupCard, card: card)
                self.runAttestation(session, response: response, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(linkingCommand) {}
        }
    }

    private func runAttestation(_ session: CardSession, response: StartBackupCardLinkingTaskResponse, completion: @escaping CompletionResult<StartBackupCardLinkingTaskResponse>) {
        let attestationTask = AttestationTask(mode: session.environment.config.attestationMode)
        attestationTask.run(in: session) { result in
            switch result {
            case .success:
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }

            withExtendedLifetime(attestationTask) {}
        }
    }

    private func isBatchIdCompatible(_ batchId: String) -> Bool {
        guard let primaryCardBatchId = primaryCard.batchId?.uppercased() else {
            return true //We found the old interrupted backup. Skip this check.
        }

        let backupCardBatchId = batchId.uppercased()

        if backupCardBatchId == primaryCardBatchId {
            return true
        }

        if BatchId.isDetached(backupCardBatchId) || BatchId.isDetached(primaryCardBatchId) {
            return false
        }

        return true
    }
}

public struct BatchId {
    private static let detached: [String] = ["AC01", "AC02", "CB95"]

    public static func isDetached(_ batchId: String) -> Bool {
        BatchId.detached.contains(batchId)
    }
}
