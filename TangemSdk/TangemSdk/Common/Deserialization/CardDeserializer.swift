//
//  CardSerializer.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct CardDeserializer {
    var allowNotPersonalized: Bool = false
    
    /// Card deserializaton helper
    /// - Parameters:
    ///   - isAccessCodeSetLegacy: isAccessCodeSet information for cards with COS before 4.33
    ///   - decoder: Common TlvDecoder
    ///   - cardDataDecoder: TlvDecoder for cardData
    /// - Throws: Deserialization errors
    /// - Returns: Card
    func deserialize(isAccessCodeSetLegacy: Bool, decoder: TlvDecoder, cardDataDecoder: TlvDecoder?) throws -> Card {
        let cardStatus: Card.Status = try decoder.decode(.status)
        try assertStatus(cardStatus)
        try assertActivation(try decoder.decode(.isActivated))
        
        guard let cardDataDecoder = cardDataDecoder  else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let firmware = FirmwareVersion(stringValue: try decoder.decode(.firmwareVersion))
        let cardSettingsMask: CardSettingsMask = try decoder.decode(.settingsMask)

        let isPasscodeSet: Bool? = firmware >= .isPasscodeStatusAvailable ?
            !(try decoder.decode(.pin2IsDefault)) : nil
        
        let isAccessCodeSet: Bool? = firmware >= .isAccessCodeStatusAvailable ?
            !(try decoder.decode(.pinIsDefault)) : nil
        
        let defaultCurve: EllipticCurve? = try decoder.decode(.curveId)
        let supportedCurves = getSupportedCurves(for: firmware, defaultCurve: defaultCurve)
        
        var wallets: [Card.Wallet] = []
        var remainingSignatures: Int? = nil
        
        if firmware < .multiwalletAvailable, cardStatus == .loaded {
            remainingSignatures = try decoder.decode(.walletRemainingSignatures)
            
            let walletSettings = Card.Wallet.Settings(mask: cardSettingsMask.toWalletSettingsMask())
            
            guard let defaultCurve = defaultCurve else {
                throw TangemSdkError.decodingFailed("Missing curve id")
            }

            let wallet = Card.Wallet(publicKey: try decoder.decode(.walletPublicKey),
                                     chainCode: nil,
                                     curve: defaultCurve,
                                     settings: walletSettings,
                                     totalSignedHashes: try decoder.decode(.walletSignedHashes),
                                     remainingSignatures: remainingSignatures,
                                     index: 0,
                                     proof: nil,
                                     isImported: false,
                                     hasBackup: false)
            
            wallets.append(wallet)
        }
        
        
        let manufacturer = Card.Manufacturer(name: try decoder.decode(.manufacturerName),
                                             manufactureDate: try cardDataDecoder.decode(.manufactureDateTime),
                                             signature: try cardDataDecoder.decode(.cardIDManufacturerSignature))
        
        let issuer = Card.Issuer(name: try cardDataDecoder.decode(.issuerName),
                                 publicKey: try decoder.decode(.issuerPublicKey))
        
        let securityDelay: Int? = try decoder.decode(.pauseBeforePin2)

        let securityDelayMs = securityDelay.map { $0 * 10 } ?? 0

        let settings = Card.Settings(securityDelay: securityDelayMs,
                                     maxWalletsCount: try decoder.decode(.walletsCount) ?? 1, //Cos before v4 always has 1 wallet
                                     mask: cardSettingsMask,
                                     defaultSigningMethods: try decoder.decode(.signingMethod),
                                     defaultCurve: defaultCurve)
        
        let terminalIsLinked: Bool = try decoder.decode(.isLinked)
        
        let backupRawStatus: Card.BackupRawStatus? = try decoder.decode(.backupStatus)
        let backupCardsCount: Int? = try decoder.decode(.backupCount)
        let backupStatus: Card.BackupStatus? = try backupRawStatus.map { try Card.BackupStatus(from: $0, cardsCount: backupCardsCount) }

        var userSettings: Card.UserSettings
        let userSettingsMask: UserSettingsMask? = try decoder.decode(.userSettingsMask)
        if let userSettingsMask {
            userSettings = .init(from: userSettingsMask)
        } else {
            userSettings = .init(isUserCodeRecoveryAllowed: firmware >= .backupAvailable)
        }

        let card = Card(cardId: try decoder.decode(.cardId),
                        batchId: try cardDataDecoder.decode(.batchId),
                        cardPublicKey: try decoder.decode(.cardPublicKey),
                        firmwareVersion: firmware,
                        manufacturer: manufacturer,
                        issuer: issuer,
                        settings: settings,
                        userSettings: userSettings,
                        linkedTerminalStatus: terminalIsLinked ? .current : .none,
                        isAccessCodeSet: isAccessCodeSet ?? isAccessCodeSetLegacy,
                        isPasscodeSet: isPasscodeSet,
                        supportedCurves: supportedCurves,
                        backupStatus: backupStatus,
                        wallets: wallets,
                        health: try decoder.decode(.health),
                        remainingSignatures: remainingSignatures)
        
        return card
    }
    
    static func getDecoder(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> TlvDecoder {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        return TlvDecoder(tlv: tlv)
    }
    
    static func getCardDataDecoder(with environment: SessionEnvironment, from tlv: [Tlv]) throws -> TlvDecoder? {
        guard let cardDataValue = tlv.value(for: .cardData),
              let cardDataTlv = Tlv.deserialize(cardDataValue) else {
            return nil
        }
        
        return TlvDecoder(tlv: cardDataTlv)
    }
    
    private func assertActivation(_ isNeedActivation: Bool) throws {
        if isNeedActivation {
            throw TangemSdkError.notActivated
        }
    }
    
    private func assertStatus(_ status: Card.Status) throws {
        if status == .notPersonalized && !allowNotPersonalized {
            throw TangemSdkError.notPersonalized
        }
        
        if status == .purged {
            throw TangemSdkError.walletIsPurged
        }
    }
    
    private func getSupportedCurves(for fwVersion: FirmwareVersion, defaultCurve: EllipticCurve?) -> [EllipticCurve] {
        if fwVersion < .multiwalletAvailable {
            return defaultCurve.map { [$0] } ?? []
        }
        
        if fwVersion < .blsAvailable {
            return [.secp256k1, .ed25519, .secp256r1]
        }

        if fwVersion < .ed25519Slip0010Available {
            return [.secp256k1, .ed25519, .secp256r1, .bip0340, .bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP]
        }
        
        return EllipticCurve.allCases
    }
}
