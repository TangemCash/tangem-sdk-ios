//
//  .swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

//MARK:- Card Settings
public extension Card {
    struct Settings: Codable {
        /// Delay in milliseconds before executing a command that affects any sensitive data or wallets on the card
        public let securityDelay: Int
        /// Maximum number of wallets that can be created for this card
        public let maxWalletsCount: Int
        /// Is allowed to change access code
        public internal(set) var isSettingAccessCodeAllowed: Bool
        /// Is  allowed to change passcode
        public internal(set) var isSettingPasscodeAllowed: Bool
        /// Is allowed to remove access code
        public internal(set) var isRemovingUserCodesAllowed: Bool
        /// Is LinkedTerminal feature enabled
        public let isLinkedTerminalEnabled: Bool
        /// All  encryption modes supported by the card
        public let supportedEncryptionModes: [EncryptionMode]
        /// Is allowed to write files
        public let isFilesAllowed: Bool
        /// Is allowed to use hd wallet
        public let isHDWalletAllowed: Bool
        /// Is allowed to create backup
        public let isBackupAllowed: Bool
        /// Is allowed to import  keys. COS. v6+
        public let isKeysImportAllowed: Bool
        /// Is allowed to delete wallet. COS before v4
        @SkipEncoding
        var isPermanentWallet: Bool
        /// Is overwriting issuer extra data resctricted
        @SkipEncoding
        var isOverwritingIssuerExtraDataRestricted: Bool
        /// Card's default signing methods according personalization.
        @SkipEncoding
        var defaultSigningMethods: SigningMethod?
        /// Card's default curve according personalization.
        @SkipEncoding
        var defaultCurve: EllipticCurve?
        @SkipEncoding
        var isIssuerDataProtectedAgainstReplay: Bool
        @SkipEncoding
        var isSelectBlockchainAllowed: Bool
    }
}

extension Card.Settings {
    init(securityDelay: Int, maxWalletsCount: Int,  mask: CardSettingsMask,
         defaultSigningMethods: SigningMethod? = nil, defaultCurve: EllipticCurve? = nil) {
        self.securityDelay = securityDelay
        self.maxWalletsCount = maxWalletsCount
        self.defaultSigningMethods = defaultSigningMethods
        self.defaultCurve = defaultCurve
        
        self.isSettingAccessCodeAllowed = mask.contains(.allowSetPIN1)
        self.isSettingPasscodeAllowed = mask.contains(.allowSetPIN2)
        self.isRemovingUserCodesAllowed = !mask.contains(.prohibitDefaultPIN1)
        self.isLinkedTerminalEnabled = mask.contains(.skipSecurityDelayIfValidatedByLinkedTerminal)
        self.isOverwritingIssuerExtraDataRestricted = mask.contains(.restrictOverwriteIssuerExtraData)
        self.isIssuerDataProtectedAgainstReplay = mask.contains(.protectIssuerDataAgainstReplay)
        self.isPermanentWallet = mask.contains(.permanentWallet)
        self.isSelectBlockchainAllowed = mask.contains(.allowSelectBlockchain)
        self.isHDWalletAllowed = mask.contains(.allowHDWallets)
        self.isFilesAllowed = !mask.contains(.disableFiles)
        self.isBackupAllowed = mask.contains(.allowBackup)
        self.isKeysImportAllowed = mask.contains(.allowKeysImport)
        
        var encryptionModes: [EncryptionMode] = [.strong]
        if mask.contains(.allowFastEncryption) {
            encryptionModes.append(.fast)
        }
        if mask.contains(.allowUnencrypted) {
            encryptionModes.append(.none)
        }
        
        self.supportedEncryptionModes = encryptionModes
    }
    
    func updated(with mask: CardSettingsMask) -> Card.Settings {
        return .init(securityDelay: self.securityDelay,
                     maxWalletsCount: self.maxWalletsCount,
                     mask: mask,
                     defaultSigningMethods: self.defaultSigningMethods,
                     defaultCurve: self.defaultCurve)
    }
}

// MARK: - CardSettingsMask

typealias CardSettingsMask = Card.Settings.Mask

extension Card.Settings {
    /// Stores and maps Tangem card settings.
    struct Mask: OptionSet, OptionSetCustomStringConvertible {
        let rawValue: Int
        
        init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
}

extension CardSettingsMask {
    func toWalletSettingsMask() -> WalletSettingsMask {
        return .init(rawValue: rawValue)
    }
}

// MARK: - CardSettingsMask Constants

extension CardSettingsMask {
    static let useActivation = CardSettingsMask(rawValue: 0x0002)
    static let useBlock = CardSettingsMask(rawValue: 0x0008)
    static let allowSetPIN1 = CardSettingsMask(rawValue: 0x0010)
    static let allowSetPIN2 = CardSettingsMask(rawValue: 0x0020)
    static let useCvc = CardSettingsMask(rawValue: 0x0040)
    static let prohibitDefaultPIN1 = CardSettingsMask(rawValue: 0x0080)
    static let useOneCommandAtTime = CardSettingsMask(rawValue: 0x0100)
    static let useNDEF = CardSettingsMask(rawValue: 0x0200)
    static let useDynamicNDEF = CardSettingsMask(rawValue: 0x0400)
    static let smartSecurityDelay = CardSettingsMask(rawValue: 0x0800)
    static let allowUnencrypted = CardSettingsMask(rawValue: 0x1000)
    static let allowFastEncryption = CardSettingsMask(rawValue: 0x2000)
    static let protectIssuerDataAgainstReplay = CardSettingsMask(rawValue: 0x4000)
    static let allowSelectBlockchain = CardSettingsMask(rawValue: 0x8000)
    static let disablePrecomputedNDEF = CardSettingsMask(rawValue: 0x00010000)
    static let skipSecurityDelayIfValidatedByIssuer = CardSettingsMask(rawValue: 0x00020000)
    static let skipCheckPIN2CVCIfValidatedByIssuer = CardSettingsMask(rawValue: 0x00040000)
    static let skipSecurityDelayIfValidatedByLinkedTerminal = CardSettingsMask(rawValue: 0x00080000)
    static let restrictOverwriteIssuerExtraData = CardSettingsMask(rawValue: 0x00100000)
    static let disableIssuerData = CardSettingsMask(rawValue: 0x01000000)
    static let disableUserData = CardSettingsMask(rawValue: 0x02000000)
    static let disableFiles = CardSettingsMask(rawValue: 0x04000000)
    static let permanentWallet = CardSettingsMask(rawValue: 0x0004)
    static let isReusable = CardSettingsMask(rawValue: 0x0001)
    static let allowHDWallets = CardSettingsMask(rawValue: 0x00200000)
    static let allowBackup = CardSettingsMask(rawValue: 0x00400000)
    static let allowKeysImport = CardSettingsMask(rawValue: 0x00800000)
}

// MARK: - CardSettingsMask OptionSetCodable conformance

extension CardSettingsMask: OptionSetCodable {
    enum OptionKeys: String, OptionKey {
        case useActivation
        case useBlock
        case allowSetPIN1
        case allowSetPIN2
        case useCvc
        case prohibitDefaultPIN1
        case useOneCommandAtTime
        case useNDEF
        case useDynamicNDEF
        case smartSecurityDelay
        case allowUnencrypted
        case allowFastEncryption
        case protectIssuerDataAgainstReplay
        case allowSelectBlockchain
        case disablePrecomputedNDEF
        case skipSecurityDelayIfValidatedByIssuer
        case skipCheckPIN2CVCIfValidatedByIssuer
        case skipSecurityDelayIfValidatedByLinkedTerminal
        case restrictOverwriteIssuerExtraData
        case disableIssuerData
        case disableUserData
        case disableFiles
        case isReusable
        case isPermanentWallet
        case allowHDWallets
        case allowBackup
        
        var value: CardSettingsMask {
            switch self {
            case .useActivation:
                return .useActivation
            case .useBlock:
                return .useBlock
            case .allowSetPIN1:
                return .allowSetPIN1
            case .allowSetPIN2:
                return .allowSetPIN2
            case .useCvc:
                return .useCvc
            case .prohibitDefaultPIN1:
                return .prohibitDefaultPIN1
            case .useOneCommandAtTime:
                return .useOneCommandAtTime
            case .useNDEF:
                return .useNDEF
            case .useDynamicNDEF:
                return .useDynamicNDEF
            case .smartSecurityDelay:
                return .smartSecurityDelay
            case .allowUnencrypted:
                return .allowUnencrypted
            case .allowFastEncryption:
                return .allowFastEncryption
            case .protectIssuerDataAgainstReplay:
                return .protectIssuerDataAgainstReplay
            case .allowSelectBlockchain:
                return .allowSelectBlockchain
            case .disablePrecomputedNDEF:
                return .disablePrecomputedNDEF
            case .skipSecurityDelayIfValidatedByIssuer:
                return .skipSecurityDelayIfValidatedByIssuer
            case .skipCheckPIN2CVCIfValidatedByIssuer:
                return .skipCheckPIN2CVCIfValidatedByIssuer
            case .skipSecurityDelayIfValidatedByLinkedTerminal:
                return .skipSecurityDelayIfValidatedByLinkedTerminal
            case .restrictOverwriteIssuerExtraData:
                return .restrictOverwriteIssuerExtraData
            case .disableIssuerData:
                return .disableIssuerData
            case .disableUserData:
                return .disableUserData
            case .disableFiles:
                return .disableFiles
            case .isReusable:
                return .isReusable
            case .isPermanentWallet:
                return .permanentWallet
            case .allowHDWallets:
                return .allowHDWallets
            case .allowBackup:
                return .allowBackup
            }
        }
    }
}
