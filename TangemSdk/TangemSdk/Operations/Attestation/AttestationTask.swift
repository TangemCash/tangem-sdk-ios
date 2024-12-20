//
//  AttestationTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public final class AttestationTask: CardSessionRunnable {
    private let mode: Mode
    private let trustedCardsRepo: TrustedCardsRepo = .init()
    private let onlineCardVerifier = OnlineCardVerifier()
    
    private var currentAttestationStatus: Attestation = .empty
    private var onlineAttestationPublisher = CurrentValueSubject<Attestation.Status?, Never>(nil)
    private var bag = Set<AnyCancellable>()
    
    /// If `true'`, AttestationTask will not pause nfc session after all card operatons complete. Usefull for chaining  tasks after AttestationTask. False by default
    public var shouldKeepSessionOpened = false
    
    public init(mode: Mode) {
        self.mode = mode
    }
    
    deinit {
        Log.debug("AttestationTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Attestation>) {
        guard session.environment.card != nil else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        attestCard(session, completion)
    }
    
    private func attestCard(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        AttestCardKeyCommand().run(in: session) { result in
            switch result {
            case .success:
                //This card already attested with the current or more secured mode
                if let attestation = self.trustedCardsRepo.attestation(for: session.environment.card!.cardPublicKey),
                   attestation.mode >= self.mode {
                    self.currentAttestationStatus = attestation
                    self.complete(session, completion)
                    return
                }
                
                //Continue attestation
                self.currentAttestationStatus.cardKeyAttestation = .verifiedOffline
                self.continueAttestation(session, completion)
            case .failure(let error):
                //Card attestation failed. Update status and fail attestation
                if case TangemSdkError.cardVerificationFailed = error {
                    self.currentAttestationStatus.cardKeyAttestation = .failed
                }
                
                completion(.failure(error))
            }
        }
    }
    
    private func continueAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        switch self.mode {
        case .offline:
            complete(session, completion)
        case .normal:
            runOnlineAttestation(session, completion)
            waitForOnlineAndComplete(session, completion)
        case .full:
            runOnlineAttestation(session, completion)
            runWalletsAttestation(session, completion)
        }
    }
    
    private func runWalletsAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        attestWallets(session) { result in
            switch result {
            case .success(let hasWarnings):
                //Wallets attestation completed. Update status and continue attestation
                self.currentAttestationStatus.walletKeysAttestation = hasWarnings ? .warning : .verified
                self.runExtraAttestation(session, completion)
            case .failure(let error):
                //Wallets attestation failed. Update status and fail attestation
                if case TangemSdkError.cardVerificationFailed = error {
                    self.currentAttestationStatus.walletKeysAttestation = .failed
                }
                
                completion(.failure(error))
            }
        }
    }
    
    private func runExtraAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        //TODO: ATTEST_CARD_FIRMWARE, ATTEST_CARD_UNIQUENESS
        self.waitForOnlineAndComplete(session, completion)
    }
    
    private func attestWallets(_ session: CardSession, _ completion: @escaping CompletionResult<Bool>) {
        let attestationCommands = session.environment.card!.wallets.map { AttestWalletKeyCommand(publicKey: $0.publicKey) }
      
        if attestationCommands.isEmpty {
            completion(.success(false)) //no warnings
            return
        }
        
        let hasWarnings = session.environment.card!.wallets.compactMap { $0.totalSignedHashes }
            .contains(where: { $0 > Constants.maxCounter })
        
        attestWallet(attestationCommands, commandIndex: 0, hasWarnings: hasWarnings, session, completion)
    }
    
    private func attestWallet(_ attestationCommands: [AttestWalletKeyCommand],
                              commandIndex: Int,
                              hasWarnings: Bool,
                              _ session: CardSession,
                              _ completion: @escaping CompletionResult<Bool>) {
        if commandIndex == attestationCommands.count {
            completion(.success(hasWarnings))
            return
        }
        
        attestationCommands[commandIndex].run(in: session) { result in
            switch result {
            case .success(let response):
                //check for hacking attempts with attestWallet
                let shouldWarn = response.counter.map { $0 > Constants.maxCounter } ?? false
                
                self.attestWallet(attestationCommands,
                                  commandIndex: commandIndex + 1,
                                  hasWarnings: shouldWarn ? true : hasWarnings,
                                  session,
                                  completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func runOnlineAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        let card = session.environment.card!
        //Dev card will not pass online attestation. Or, if the card already failed offline attestation, we can skip online part.
        //So, we can send the error to the publisher immediately
        if card.firmwareVersion.type == .sdk || currentAttestationStatus.cardKeyAttestation == .failed {
            onlineAttestationPublisher.send(.failed)
            return
        }
        
        onlineCardVerifier
            .getCardInfo(cardId: card.cardId, cardPublicKey: card.cardPublicKey)
            .map { _ in return Attestation.Status.verified } //We assume, that card verified, because we skip online attestation for dev cards and cards that failed keys attestation
            .catch { error -> Just<Attestation.Status> in
                if case TangemSdkError.cardVerificationFailed = error {
                    return Just(.failed)
                }

                return Just(.verifiedOffline)
            }
            .sink(receiveValue: { self.onlineAttestationPublisher.send($0) })
            .store(in: &bag)
    }

    private func waitForOnlineAndComplete(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        if !shouldKeepSessionOpened {
            session.pause() //Nothing to do with nfc anymore
        }
        
        onlineAttestationPublisher
            .compactMap { $0 }
            .sink(receiveValue: {[weak self] attestResult in
                guard let self else { return }
                
                switch attestResult {
                case .verified:
                    self.currentAttestationStatus.cardKeyAttestation = .verified
                    self.trustedCardsRepo.append(cardPublicKey: session.environment.card!.cardPublicKey, attestation:  self.currentAttestationStatus)
                case .failed:
                    self.currentAttestationStatus.cardKeyAttestation = .failed
                default: break
                }
                
                self.processAttestationReport(session, completion)
            })
            .store(in: &bag)
    }
    
    private func retryOnline( _ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        self.runOnlineAttestation(session, completion)
    }
    
    private func processAttestationReport(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        switch currentAttestationStatus.status {
        case .failed, .skipped:
            let isDevelopmentCard = session.environment.card!.firmwareVersion.type == .sdk
            session.viewDelegate.setState(.empty)
            //Possible production sample or development card
            if isDevelopmentCard || session.environment.config.allowUntrustedCards {
                session.viewDelegate.attestationDidFail(isDevelopmentCard: isDevelopmentCard) {
                    self.complete(session, completion)
                } onCancel: {
                    completion(.failure(.userCancelled))
                }
                
                return
            }
            
            completion(.failure(.cardVerificationFailed))
            
        case .verified:
            self.complete(session, completion)
            
        case .verifiedOffline:
            if session.environment.config.attestationMode == .offline {
                self.complete(session, completion)
                return
            }
            
            session.viewDelegate.setState(.empty)
            session.viewDelegate.attestationCompletedOffline() {
                self.complete(session, completion)
            } onCancel: {
                completion(.failure(.userCancelled))
            } onRetry: {
                session.viewDelegate.setState(.default)
                self.retryOnline(session, completion)
            }
            
        case .warning:
            session.viewDelegate.setState(.empty)
            session.viewDelegate.attestationCompletedWithWarnings {
                self.complete(session, completion)
            }
        }
    }
    
    private func complete(_ session: CardSession, _ completion: @escaping CompletionResult<Attestation>) {
        session.environment.card?.attestation = currentAttestationStatus
        completion(.success(currentAttestationStatus))
    }
}

public extension AttestationTask {
    enum Mode: String, StringCodable, CaseIterable, Comparable {
        case offline, normal, full
        
        public static func < (lhs: AttestationTask.Mode, rhs: AttestationTask.Mode) -> Bool {
            switch (lhs, rhs) {
            case (normal, full):
                return true
            case (offline, normal):
                return true
            case (offline, full):
                return true
            default:
                return false
            }
        }
    }
}

private extension AttestationTask {
    enum Constants {
        //Attest wallet count or sign command count greater this value is looks suspicious.
        static let maxCounter = 100000
    }
}
