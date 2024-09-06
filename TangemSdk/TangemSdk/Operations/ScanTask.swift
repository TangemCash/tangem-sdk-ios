//
//  ScanTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Task that allows to read Tangem card and verify its private key.
/// Returns data from a Tangem card after successful completion of `ReadCommand` and `AttestWalletKeyCommand`, subsequently.
public final class ScanTask: CardSessionRunnable {
    public var shouldAskForAccessCode: Bool { false }
    
    private var attestationTask: AttestationTask? = nil

    public init() {}
    
    deinit {
        Log.debug("ScanTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card  else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        //We have to retrieve passcode status information for cards with COS before v4.01 with checkUserCodes command for backward compatibility.
        //checkUserCodes command for cards with COS <=1.19 not supported because of persistent SD.
        //We cannot run checkUserCodes command for cards whose `isRemovingUserCodesAllowed` is set to false because of an error
        if card.firmwareVersion < .isPasscodeStatusAvailable
            && card.firmwareVersion.doubleValue > 1.19
            && card.settings.isRemovingUserCodesAllowed {
            checkUserCodes(session, completion)
        } else {
            deriveKeysIfNeeded(session, completion)
        }
    }

    private func checkUserCodes(_ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        CheckUserCodesCommand().run(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card?.isPasscodeSet = response.isPasscodeSet
                self.runAttestation(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func deriveKeysIfNeeded(_ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }

        let defaultPaths = session.environment.config.defaultDerivationPaths
        guard card.firmwareVersion >= .hdWalletAvailable, card.settings.isHDWalletAllowed, !defaultPaths.isEmpty else {
            self.runAttestation(session, completion)
            return
        }
        
        let derivations = card.wallets.reduce(into: [Data: [DerivationPath]]()) { (result, wallet) in
            if let paths = defaultPaths[wallet.curve], !paths.isEmpty {
                result[wallet.publicKey] = paths
            }
        }
        
        guard !derivations.isEmpty else {
            self.runAttestation(session, completion)
            return
        }
        
        let derivationTask = DeriveMultipleWalletPublicKeysTask(derivations)
        derivationTask.run(in: session) { result in
            switch result {
            case .success:
                self.runAttestation(session, completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func runAttestation(_ session: CardSession, _ completion: @escaping CompletionResult<Card>) {
        attestationTask = AttestationTask(mode: session.environment.config.attestationMode)
        attestationTask!.run(in: session) { result in
            switch result {
            case .success:
                guard let card = session.environment.card  else {
                    completion(.failure(.missingPreflightRead))
                    return
                }
                
                completion(.success(card))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
