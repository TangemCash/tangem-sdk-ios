//
//  StartBackupCardLinkingTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

@available(iOS 13.0, *)
final class StartBackupCardLinkingTask: CardSessionRunnable {
    private let primaryCard: PrimaryCard
    private let addedBackupCards: [String]
    private let onlineCardVerifier = OnlineCardVerifier()
    private let skipCompatibilityChecks: Bool
    private var cancellable: AnyCancellable? = nil
    private var linkingCommand: StartBackupCardLinkingCommand? = nil
    
    init(primaryCard: PrimaryCard, addedBackupCards: [String], skipCompatibilityChecks: Bool = false) {
        self.primaryCard = primaryCard
        self.addedBackupCards = addedBackupCards
        self.skipCompatibilityChecks = skipCompatibilityChecks
    }
    
    deinit {
        Log.debug("StartBackupCardLinkingTask deinit")
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<BackupCard>) {
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
        
        linkingCommand = StartBackupCardLinkingCommand(primaryCardLinkingKey: primaryCard.linkingKey)
        linkingCommand!.run(in: session) { result in
            switch result {
            case .success(let rawCard):
                self.loadIssuerSignature(rawCard, session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func loadIssuerSignature(_ rawCard: RawBackupCard, _ session: CardSession, _ completion: @escaping CompletionResult<BackupCard>) {
        if session.environment.card?.firmwareVersion.type == .sdk {
            let issuerPrivateKey = Data(hexString: "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92")
            do {
                let issuerSignature = try rawCard.cardPublicKey.sign(privateKey: issuerPrivateKey)
                completion(.success(BackupCard(rawCard, issuerSignature: issuerSignature)))
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
            return
        }
        
        cancellable = onlineCardVerifier
            .getCardData(cardId: rawCard.cardId, cardPublicKey: rawCard.cardPublicKey)
            .sink(receiveCompletion: { receivedCompletion in
                if case  .failure = receivedCompletion {
                    completion(.failure(.issuerSignatureLoadingFailed))
                }
            }, receiveValue: { response in
                guard let signature = response.issuerSignature else {
                    completion(.failure(.issuerSignatureLoadingFailed))
                    return
                }
                
                let backupCard = BackupCard(rawCard, issuerSignature: signature)
                completion(.success(backupCard))
            })
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
