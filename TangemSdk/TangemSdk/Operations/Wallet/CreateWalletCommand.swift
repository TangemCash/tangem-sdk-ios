//
//  CreateWalletCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Response from the Tangem card after `CreateWalletCommand` or `CreateWalletTask`.
public struct CreateWalletResponse: JSONStringConvertible {
    /// Unique Tangem card ID number
    public let cardId: String
    /// Created wallet
    public let wallet: Card.Wallet
}

/**
 * This task will create a new wallet on the card
 * A key pair WalletPublicKey / WalletPrivateKey is generated and securely stored in the card.
 * App will need to obtain Wallet_PublicKey from the response of `CreateWalletCommand`or `ScanTask`
 * and then transform it into an address of corresponding blockchain wallet
 * according to a specific blockchain algorithm.
 * WalletPrivateKey is never revealed by the card and will be used by `SignHash` or `SignHashes` and `AttestWalletKeyCommand`.
 * RemainingSignature is set to MaxSignatures.
 */
final class CreateWalletCommand: Command {
    var requiresPasscode: Bool { return true }
    var walletIndex: Int = 0
    
    private let curve: EllipticCurve
    private let privateKey: ExtendedPrivateKey?
    private let signingMethod = SigningMethod.signHash
    
    /// Default initializer
    /// - Parameter curve: Elliptic curve of the wallet.  `Card.supportedCurves` contains all curves supported by the card
    init(curve: EllipticCurve) {
        self.curve = curve
        self.privateKey = nil
    }

    /// Use this initializer to import a key. COS v6+.
    /// - Parameter curve: Elliptic curve of the wallet.  `Card.supportedCurves` contains all curves supported by the card
    /// - Parameter privateKey: A private key to import
    init(curve: EllipticCurve, privateKey: ExtendedPrivateKey) {
        self.curve = curve
        self.privateKey = privateKey
    }
    
    deinit {
        Log.debug("CreateWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion >= .multiwalletAvailable,
           !card.settings.isSelectBlockchainAllowed {
            return .walletCannotBeCreated
        }
        
        guard card.supportedCurves.contains(curve) else {
            return TangemSdkError.unsupportedCurve
        }
        
        if card.firmwareVersion < .multiwalletAvailable {
            if let cardSigningMethods = card.settings.defaultSigningMethods,
               !signingMethod.isSubset(of: cardSigningMethods) {
                return TangemSdkError.unsupportedWalletConfig
            }
        }

        if privateKey != nil {
            if card.firmwareVersion < .keysImportAvailable {
                return TangemSdkError.notSupportedFirmwareVersion
            }

            if !card.settings.isKeysImportAllowed {
                return TangemSdkError.keysImportDisabled
            }

            // Checking the existence of the key in advance. The next level of this check is in a card.
            // This check will fail for compressed secp256r1 keys and bls keys
            if let extendedKey = try? privateKey?.makePublicKey(for: curve),
               card.wallets[extendedKey.publicKey] != nil {
                return TangemSdkError.walletAlreadyCreated
            }
        }

        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<CreateWalletResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                var wallets: [Card.Wallet] = session.environment.card?.wallets ?? []
                wallets.append(response.wallet)
                session.environment.card?.wallets = wallets.sorted(by: { $0.index < $1.index })
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            guard let card = card else { return error }
            
            if card.firmwareVersion >= .isPasscodeStatusAvailable,
               let isPasscodeSet = card.isPasscodeSet, !isPasscodeSet {
                return .alreadyCreated
            }
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }
        
        self.walletIndex = try calculateWalletIndex(for: card)
        
        if card.firmwareVersion >= .multiwalletAvailable {
            let maskBuilder = MaskBuilder<WalletSettingsMask>()
            maskBuilder.add(.isReusable) //The newest v4 cards ignore this setting, the card's settings value used instead
            
            try tlvBuilder.append(.settingsMask, value: maskBuilder.build())
                .append(.curveId, value: curve)
                .append(.signingMethod, value: signingMethod)
                .append(.walletIndex, value: walletIndex)
        }

        if let privateKey {
            try tlvBuilder.append(.walletPrivateKey, value: privateKey.privateKey)
            if !privateKey.chainCode.isEmpty {
                try tlvBuilder.append(.walletHDChain, value: privateKey.chainCode)
            }
        }
        
        return CommandApdu(.createWallet, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> CreateWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        let wallet: Card.Wallet
        
        switch card.firmwareVersion {
        case .createWalletResponseAvailable...:
            //Newest v4 cards don't have their own wallet settings, so we should take them from the card's settings
            wallet = try WalletDeserializer(isDefaultPermanentWallet: card.settings.isPermanentWallet)
                .deserializeWallet(from: decoder)
        case .multiwalletAvailable...: //We don't have a wallet response so we use to create it ourselves
            wallet = try makeWalletLegacy(decoder: decoder,
                                          index: try decoder.decode(.walletIndex),
                                          remainingSignatures: nil, //deprecated
                                          isPermanentWallet: false) //we restrict to create permanent wallets by sdk design
        default: //We don't have a wallet response so we use to create it ourselves
            wallet = try makeWalletLegacy(decoder: decoder,
                                          index: 0,
                                          remainingSignatures: card.remainingSignatures,
                                          isPermanentWallet: card.settings.isPermanentWallet)
        }
        
        return CreateWalletResponse(cardId: try decoder.decode(.cardId), wallet: wallet)
    }
    
    private func makeWalletLegacy(decoder: TlvDecoder,
                                  index: Int,
                                  remainingSignatures: Int?,
                                  isPermanentWallet: Bool) throws -> Card.Wallet {
        return Card.Wallet(publicKey: try decoder.decode(.walletPublicKey),
                           chainCode: nil,
                           curve: curve, // It's safe to use this property because create wallet command will not execute successfully with the wrong curve
                           settings: Card.Wallet.Settings(isPermanent: isPermanentWallet),
                           totalSignedHashes: 0,
                           remainingSignatures: remainingSignatures,
                           index: index,
                           proof: nil,
                           isImported: false,
                           hasBackup: false)
    }
    
    private func calculateWalletIndex(for card: Card) throws -> Int {
        let maxIndex = card.settings.maxWalletsCount //We need to execute this wallet index calculation stuff only after precheck because of correct error mapping. Run fires only before precheck. And precheck will not fire if error handling disabled
        let occupiedIndices = card.wallets.map { $0.index }
        let allIndices = 0..<maxIndex
        if let firstAvailableIndex = allIndices.filter({ !occupiedIndices.contains($0) }).sorted().first {
            return firstAvailableIndex
        } else {
            if maxIndex == 1 {
                //already created for old cards mostly
                throw TangemSdkError.alreadyCreated
            } else {
                throw TangemSdkError.maxNumberOfWalletsCreated
            }
        }
    }
}
