//
//  CreateWalletTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/**
 * This task will create a new wallet on the card
 * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
 * App will need to obtain Wallet_PublicKey from the response of `CreateWalletTask`or `ScanTask`
 * and then transform it into an address of corresponding blockchain wallet
 * according to a specific blockchain algorithm.
 * WalletPrivateKey is never revealed by the card and will be used by `SignHash` or `SignHashes` and `AttestWalletKeyCommand`.
 * RemainingSignature is set to MaxSignatures.
 */
public class CreateWalletTask: CardSessionRunnable {
    public var encryptionMode: EncryptionMode {
        privateKey == nil ? .none : .strong
    }

    private let curve: EllipticCurve
    private let privateKey: ExtendedPrivateKey?
    private var derivationTask: DeriveWalletPublicKeysTask? = nil

    /// Default initializer
    /// - Parameter curve: Elliptic curve of the wallet.  `Card.supportedCurves` contains all curves supported by the card
    public init(curve: EllipticCurve) {
        self.curve = curve
        self.privateKey = nil
    }

    /// Use this initializer to import a key. COS v6+.
    /// - Parameter curve: Elliptic curve of the wallet.  `Card.supportedCurves` contains all curves supported by the card
    /// - Parameter privateKey: A private key to import
    public init(curve: EllipticCurve, privateKey: ExtendedPrivateKey) {
        self.curve = curve
        self.privateKey = privateKey
    }
    
    deinit {
        Log.debug("CreateWalletTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        let command = makeCommand()
        command.run(in: session) { result in
            switch result {
            case .success(let response):
                self.deriveKeysIfNeeded(for: response, in: session, completion: completion)
            case .failure(let error):
                if case .invalidState = error { //Wallet already created but we didn't get the proper response from the card. Rescan and retrieve the wallet
                    Log.debug("Received wallet creation error. Try rescan and retrieve created wallet")
                    self.scanAndRetrieveCreatedWallet(at: command.walletIndex, in: session, completion: completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func scanAndRetrieveCreatedWallet(at index: Int, in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if card.firmwareVersion < .multiwalletAvailable {
            ReadCommand().run(in: session) { result in
                switch result {
                case .success:
                    self.mapWallet(at: index, in: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            ReadWalletsListCommand().run(in: session) { result in
                switch result {
                case .success:
                    self.mapWallet(at: index, in: session, completion: completion)
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func mapWallet(at index: Int, in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if let createdWallet = card.wallets.first(where: { $0.index == index }) {
            let response = CreateWalletResponse(cardId: card.cardId, wallet: createdWallet)
            self.deriveKeysIfNeeded(for: response, in: session, completion: completion)
        } else {
            Log.debug("Wallet not found after rescan.")
            completion(.failure(TangemSdkError.unknownError))
        }
    }
    
    private func deriveKeysIfNeeded(for response: CreateWalletResponse, in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        guard card.firmwareVersion >= .hdWalletAvailable, card.settings.isHDWalletAllowed,
              let paths = session.environment.config.defaultDerivationPaths[response.wallet.curve],
              !paths.isEmpty else {
                  completion(.success(response))
                  return
              }
        
        derivationTask = DeriveWalletPublicKeysTask(walletPublicKey: response.wallet.publicKey, derivationPaths: paths)
        derivationTask!.run(in: session) { result in
            switch result {
            case .success(let derivedKeys):
                var mutableWallet = response.wallet
                mutableWallet.derivedKeys = derivedKeys
                let updatedResponse = CreateWalletResponse(cardId: response.cardId, wallet: mutableWallet)
                completion(.success(updatedResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func makeCommand() -> CreateWalletCommand {
        if let privateKey {
            return .init(curve: curve, privateKey: privateKey)
        }

        return .init(curve: curve)
    }
}
