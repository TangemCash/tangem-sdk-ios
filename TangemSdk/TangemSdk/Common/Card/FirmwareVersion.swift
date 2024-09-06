//
//  FirmwareVersion.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Holds information about card firmware version included version saved on card `version`,
/// splitted to `major`, `minor` and `patch` and `FirmwareType`
public struct FirmwareVersion: Codable {
    /// Version that saved on card
    public let stringValue: String
    
    public var doubleValue: Double {
        Double("\(major).\(minor)")!
    }
    
    private(set) public var major: Int = 0
    private(set) public var minor: Int = 0
    private(set) public var patch: Int = 0
    private(set) public var type: FirmwareType
    
    public init(stringValue: String) {
        self.stringValue = stringValue
        
        let versionCleaned = stringValue.remove("\0")
        
        let cardTypeStr = versionCleaned.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789."))
        let result = versionCleaned.remove(cardTypeStr)
        
        var splitted = result.split(separator: ".")
        if let majorStr = splitted.first, let major = Int(majorStr) {
            self.major = major
            splitted.removeFirst()
        }
        
        if let minorStr = splitted.first, let minor = Int(minorStr) {
            self.minor = minor
            splitted.removeFirst()
        }
        
        if let patchStr = splitted.first, let patch = Int(patchStr) {
            self.patch = patch
        }
        
        type = .type(for: cardTypeStr)
    }
    
    public init(major: Int, minor: Int, patch: Int = 0, type: FirmwareType = .sdk) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.type = type
        
        let patchSuffix = ".\(patch)"
        var version = "\(major).\(minor)"
        version += patch != 0 ? patchSuffix : ""
        version += type.rawValue
        
        self.stringValue = version
    }
}

extension FirmwareVersion: Comparable {
    public static func < (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        } else if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        } else {
            return lhs.patch < rhs.patch
        }
    }
    
    public static func == (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
        lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }
    
    public static func >= (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major > rhs.major
        } else if lhs.minor != rhs.minor {
            return lhs.minor > rhs.minor
        } else {
            return lhs.patch >= rhs.patch
        }
    }
    
    public static func < (lhs: FirmwareVersion?, rhs: FirmwareVersion) -> Bool {
        guard let lhs = lhs else { return false }
        
        return lhs < rhs
    }
    
    public static func >= (lhs: FirmwareVersion?, rhs: FirmwareVersion) -> Bool {
        guard let lhs = lhs else { return false }
        
        return lhs >= rhs
    }
    
}
//MARK: - Constants
public extension FirmwareVersion { //todo: move all doubleValue checks to constants, group production cos
    /// Multi-wallet
    static let multiwalletAvailable = FirmwareVersion(major: 4, minor: 0)
    /// BLS
    static let blsAvailable = FirmwareVersion(major: 4, minor: 45)
    /// Field on card that describes is passcode is default value or not
    static let isPasscodeStatusAvailable = FirmwareVersion(major: 4, minor: 1)
    /// Field on card that describes is accessCode is default value or not
    static let isAccessCodeStatusAvailable = FirmwareVersion(major: 4, minor: 33)
    /// Read-write files
    static let filesAvailable = FirmwareVersion(major: 3, minor: 29)
    /// HD Wallet
    static let hdWalletAvailable = FirmwareVersion(major: 4, minor: 39)
    /// Is create wallet command answers with the whole wallet
    static let createWalletResponseAvailable = FirmwareVersion(major: 4, minor: 25)
    /// Backup availavle
    static let backupAvailable = FirmwareVersion(major: 4, minor: 39)
    /// Wallet ownership confirmation available
    static let walletOwnershipConfirmationAvailable = FirmwareVersion(major: 2, minor: 1)
    /// Keys import support
    static let keysImportAvailable = FirmwareVersion(major: 6, minor: 21)
    /// Tmp range for visa cards
    static let visaRange = 5.25...5.30
    /// ed25519_slip0010
    static let ed25519Slip0010Available = FirmwareVersion(major: 6, minor: 33)
}

public extension FirmwareVersion {
    enum FirmwareType: String, StringCodable, CaseIterable, JSONStringConvertible {
        case sdk = "d SDK" //todo fix
        case release = "r"
        case special
        
        static func type(for str: String) -> FirmwareType {
            let trimmed = str.trim()
            
            if trimmed.isEmpty {
                return .release
            }
            
            return FirmwareType(rawValue: trimmed) ?? .special
        }
    }
}
