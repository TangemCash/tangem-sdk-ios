//
//  Wallet.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public extension Card {
    /// Describing wallets created on card
    struct Wallet: Codable {
        /// Wallet's public key.  For `secp256k1`, the key can be compressed or uncompressed. Use `Secp256k1Key` for any conversions.
        public let publicKey: Data
        /// Optional chain code for BIP32 derivation.
        public let chainCode: Data?
        /// Elliptic curve used for all wallet key operations.
        public let curve: EllipticCurve
        /// Wallet's settings
        public let settings: Settings
        /// Total number of signed hashes returned by the wallet since its creation
        /// COS 1.16+
        public var totalSignedHashes: Int?
        /// Remaining number of `Sign` operations before the wallet will stop signing any data.
        /// - Note: This counter were deprecated for cards with COS 4.0 and higher
        public var remainingSignatures: Int?
        /// Index of the wallet in the card storage
        public let index: Int
        /// Proof for BLS Proof of possession scheme (POP)
        public let proof: Data?
        /// Has this key been imported to a card. E.g. from seed phrase
        public let isImported: Bool
        /// Does this wallet has a backup
        public var hasBackup: Bool
        /// Derived keys according to `Config.defaultDerivationPaths`
        public var derivedKeys: DerivedKeys = [:]
    }
}

public extension Card.Wallet {
    struct Settings: Codable {
        /// if true, erasing the wallet will be prohibited
        public let isPermanent: Bool
    }
}

public extension Card.Wallet {
    /// Status of the wallet. 
    enum Status: Int, StatusType, JSONStringConvertible { //TODO: Specify
        /// Wallet not created
        case empty = 1
        /// Wallet created and can be used for signing
        case loaded = 2
        /// Wallet was purged and can't be recreated or used for signing
        case purged = 3
        /// Empty wallet created because of error durung backup
        case emptyBackedUp = 0x81
        /// Wallet created and can be used for signing, backup data read
        case backedUp = 0x82
        /// Wallet was purged and can't be recreated or used for signing, but backup data read and wallet can be usable on backup card
        case backedUpAndPurged = 0x83
        /// Wallet was imported
        case imported = 0x42
        /// Wallet was imported and backed up
        case backedUpImported = 0xC2
    }
}

extension Card.Wallet.Status {
    var isBackedUp: Bool {
        switch self {
        case .backedUp, .backedUpAndPurged, .backedUpImported:
            return true
        default:
            return false
        }
    }

    var isImported: Bool {
        switch self {
        case .imported, .backedUpImported:
            return true
        default:
            return false
        }
    }

    var isAvailable: Bool {
        switch self {
        case .empty, .purged, .backedUpAndPurged, .emptyBackedUp:
            return false
        default:
            return true
        }
    }
}

extension Card.Wallet.Settings {
    /// Stores and maps Wallet settings
    /// - Note: Available only for cards with COS v.4.0
    struct Mask: OptionSet, OptionSetCustomStringConvertible {
        var rawValue: Int
        
        static let isPermanent = Mask(rawValue: 0x0004)
        static let isReusable = Mask(rawValue: 0x0001)
        
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

extension Card.Wallet.Settings {
    init(mask: WalletSettingsMask) {
        self.isPermanent = mask.contains(.isPermanent)
    }
}

typealias WalletSettingsMask = Card.Wallet.Settings.Mask

extension WalletSettingsMask: OptionSetCodable {
    enum OptionKeys: String, OptionKey {
        case isPermanent
        case isReusable
        
        var value: WalletSettingsMask {
            switch self {
            case .isPermanent:
                return .isPermanent
            case .isReusable:
                return .isReusable
            }
        }
    }
}
