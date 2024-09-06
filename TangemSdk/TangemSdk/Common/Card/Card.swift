//
//  Card.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

///Response for `ReadCommand`. Contains detailed card information.
public struct Card: Codable, JSONStringConvertible {
    /// Unique Tangem card ID number.
    public let cardId: String
    /// Tangem internal manufacturing batch ID.
    public let batchId: String
    /// Public key that is used to authenticate the card against manufacturer’s database.
    /// It is generated one time during card manufacturing.
    public let cardPublicKey: Data
    /// Version of Tangem Card Operation System.
    public let firmwareVersion: FirmwareVersion
    /// Information about manufacturer
    public let manufacturer: Manufacturer
    /// Information about issuer
    public let issuer: Issuer
    /// Card setting, that were set during the personalization process
    public var settings: Settings
    /// Card settings, that were set during the personalization process and can be changed by user directly
    public internal(set) var userSettings: UserSettings
    /// When this value is `current`, it means that the application is linked to the card,
    /// and COS will not enforce security delay if `SignCommand` will be called
    /// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
    /// to be signed made with `TlvTag.TerminalPublicKey`.
    public let linkedTerminalStatus: LinkedTerminalStatus
    /// Access code (aka PIN1) is set.
    public var isAccessCodeSet: Bool
    /// Passcode (aka PIN2) is set.
    /// COS v. 4.33 and higher - always available
    /// COS v. 1.19 and lower - always unavailable
    /// COS  v > 1.19 &&  v < 4.33 - available only if `isRemovingUserCodesAllowed` set to true
    public var isPasscodeSet: Bool?
    /// Array of ellipctic curves, supported by this card. Only wallets with these curves can be created.
    public let supportedCurves: [EllipticCurve]
    /// Status of card's backup
    public var backupStatus: BackupStatus?
    /// Wallets, created on the card, that can be used for signature
    public var wallets: [Wallet] = []
    /// Card's attestation report
    public var attestation: Attestation = .empty
    /// Any non-zero value indicates that the card experiences some hardware problems.
    /// User should withdraw the value to other blockchain wallet as soon as possible.
    /// Non-zero Health tag will also appear in responses of all other commands.
    @SkipEncoding
    var health: Int? //todo refactor
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    /// - Note: This counter were deprecated for cards with COS 4.0 and higher
    @SkipEncoding
    var remainingSignatures: Int?
}

public extension Card {
    struct Manufacturer: Codable {
        /// Card manufacturer name.
        public let name: String
        /// Timestamp of manufacturing.
        public let manufactureDate: Date
        /// Signature of CardId with manufacturer’s private key. COS 1.21+
        public let signature: Data?
    }
    
    struct Issuer: Codable {
        /// Name of the issuer.
        public let name: String
        /// Public key that is used by the card issuer to sign IssuerData field.
        public let publicKey: Data
    }
    
    /// Card's linked terminal status. SDK can generate asymmetric key-pair and then use it for linking a card.
    enum LinkedTerminalStatus: String, Codable {
        // Current app instance is linked to the card
        case current
        // The other app/device is linked to the card
        case other
        // No app/device is linked
        case none
    }
    
    /// Card's backup status
    enum BackupStatus: Codable, Equatable {
        case noBackup
        case cardLinked(cardsCount: Int)
        case active(cardsCount: Int)
        
        public var isActive: Bool {
            switch self {
            case .active:
                return true
            default:
                return false
            }
        }

        public var canBackup: Bool {
            switch self {
            case .noBackup:
                return true
            default:
                return false
            }
        }

        public var linkedCardsCount: Int {
            switch self {
            case .active(let cardsCount):
                return cardsCount
            case .cardLinked(let cardsCount):
                return cardsCount
            case .noBackup:
                return 0
            }
        }

        public var backupCardsCount: Int {
            switch self {
            case .active(let cardsCount):
                return cardsCount
            default:
                return 0
            }
        }

        public init(from decoder: Decoder) throws {
            let codableStruct = try BackupStatusCodable(from: decoder)
            try self.init(from: codableStruct.status, cardsCount: codableStruct.cardsCount )
        }
        
        init(from rawStatus: BackupRawStatus, cardsCount: Int?) throws {
            switch rawStatus {
            case .active:
                guard let cardsCount = cardsCount else {
                    throw TangemSdkError.decodingFailed("Failed to decode BackupStatus")
                }
                
                self = .active(cardsCount: cardsCount)
            case .cardLinked:
                guard let cardsCount = cardsCount else {
                    throw TangemSdkError.decodingFailed("Failed to decode BackupStatus")
                }
                
                self = .cardLinked(cardsCount: cardsCount)
            case .noBackup:
                self = .noBackup
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            let codableStruct = toBackupStatusCodable()
            try codableStruct.encode(to: encoder)
        }
        
        private func toBackupStatusCodable() -> BackupStatusCodable {
            switch self {
            case .active(let cardsCount):
                return BackupStatusCodable(status: .active, cardsCount: cardsCount)
            case .cardLinked(let cardsCount):
                return BackupStatusCodable(status: .cardLinked, cardsCount: cardsCount)
            case .noBackup:
                return BackupStatusCodable(status: .noBackup, cardsCount: nil)
            }
        }
        
        private struct BackupStatusCodable: Codable {
            let status: BackupRawStatus
            let cardsCount: Int?
        }
    }
}

extension Card {
    /// Status of the card and its wallet.
    enum Status: Int, StatusType { //TODO: TBD
        case notPersonalized = 0
        case empty = 1
        case loaded = 2
        case purged = 3
    }
    
    /// Card's backup status
    enum BackupRawStatus: String, StringCodable {
        case noBackup
        case cardLinked
        case active
        
        var intValue: Int { //TODO: make generic tlvintconvertible
            switch self {
            case .noBackup:
                return 0
            case .cardLinked:
                return 1
            case .active:
                return 2
            }
        }
        
        static func make(from intValue: Int) -> BackupRawStatus? {
            if intValue == 0 {
                return .noBackup
            } else if intValue == 1 {
                return .cardLinked
            } else if intValue == 2 {
                return .active
            }
            
            return nil
        }
    }
}

