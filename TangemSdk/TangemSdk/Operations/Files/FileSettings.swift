//
//  FileSettings.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct FileSettings: Codable {
    public let isPermanent: Bool
    public let visibility: FileVisibility
}

extension FileSettings {
    init?(_ data: Data?) throws {
        guard let data = data else { return nil }
        
        guard let significantByte = data.last else {
            throw TangemSdkError.decodingFailed("Failed to decode FileSettings")
        }
        
        if data.count == 2 { //v3 version
            self.isPermanent = false
            self.visibility = significantByte == 1 ? .public : .private
        } else {
            let settings = FileRawSettings(rawValue: significantByte)
            self.isPermanent = settings.contains(.isPermanent)
            self.visibility = settings.contains(.isPublic) ? .public : .private
        }
    }
}

///File visibility. Private files can be read only with security delay or user code if set
public enum FileVisibility: String, Codable {
    /// User can read public files without any codes
    case `public`
    /// User can read private files only with security delay or user code if set
    case `private`
    
    func serializeValue(for fwVersion: FirmwareVersion) -> Data {
        if fwVersion.doubleValue < 4 {
            return Data([Byte(0), permissionsRawValue])
        } else {
            return Data(permissionsRawValue)
        }
    }
    
    fileprivate var permissionsRawValue: Byte {
        switch self {
        case .public:
            return FileRawSettings.isPublic.rawValue
        case .private:
            return Byte(0)
        }
    }
}

fileprivate struct FileRawSettings: OptionSet {
    static let isPublic: FileRawSettings = .init(rawValue: 0x01)
    static let isPermanent: FileRawSettings = .init(rawValue: 0x10)
    
    let rawValue: Byte
    
    init(rawValue: Byte) {
        self.rawValue = rawValue
    }
}
