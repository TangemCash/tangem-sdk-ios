//
//  CardWalletDeserializer.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialize v4 walelts only
class WalletDeserializer {
    private let isDefaultPermanentWallet: Bool
    /// Default initializer
    /// - Parameter isDefaultPermanentWallet: Newest v4 cards don't have their own wallet settings, so we should take them from the card's settings
    internal init(isDefaultPermanentWallet: Bool) {
        self.isDefaultPermanentWallet = isDefaultPermanentWallet
    }
    
    func deserializeWallets(from decoder: TlvDecoder) throws -> (wallets: [Card.Wallet], totalReceived: Int) {
        let cardWalletsData: [Data] = try decoder.decodeArray(.cardWallet)
        
        guard !cardWalletsData.isEmpty else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let walletDecoders: [TlvDecoder] = cardWalletsData.compactMap {
            guard let infoTlvs = Tlv.deserialize($0) else { return nil }
            
            return TlvDecoder(tlv: infoTlvs)
        }
        
        let wallets: [Card.Wallet] = try walletDecoders.compactMap {
            do {
                return try deserializeWallet(from: $0)
            } catch TangemSdkError.walletNotFound {
                return nil
            }
        }
        
        return (wallets, cardWalletsData.count)
    }
    
    func deserializeWallet(from decoder: TlvDecoder) throws -> Card.Wallet {
        let status: Card.Wallet.Status = try decoder.decode(.status)

        if !status.isAvailable {
            throw TangemSdkError.walletNotFound
        }
        
        return try deserialize(from: decoder, status: status)
    }
    
    private func deserialize(from decoder: TlvDecoder, status: Card.Wallet.Status) throws -> Card.Wallet {
        let mask: WalletSettingsMask? = try decoder.decode(.settingsMask)
        let settings: Card.Wallet.Settings = mask.map {.init(mask: $0)}
            ?? .init(isPermanent: isDefaultPermanentWallet) //Newest v4 cards don't have their own wallet settings, so we should take them from the card's settings

        return Card.Wallet(publicKey: try decoder.decode(.walletPublicKey),
                           chainCode: try decoder.decode(.walletHDChain),
                           curve: try decoder.decode(.curveId),
                           settings: settings,
                           totalSignedHashes: try decoder.decode(.walletSignedHashes),
                           remainingSignatures: nil,
                           index: try decoder.decode(.walletIndex),
                           proof: try decoder.decode(.proof),
                           isImported: status.isImported,
                           hasBackup: status.isBackedUp)
    }
}
