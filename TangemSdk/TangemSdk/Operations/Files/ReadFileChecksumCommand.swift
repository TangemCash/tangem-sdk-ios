//
//  ReadFileChecksumCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `ReadFileChecksumCommand`
public struct ReadFileChecksumResponse: JSONStringConvertible {
    public let cardId: String
    public let checksum: Data
    public let fileIndex: Int?
}

/// The command that prompts the card to create a file checksum. This checksum is used to check the integrity of the file on the card
public final class ReadFileChecksumCommand: Command {
    public var shouldReadPrivateFiles = false
    
    public var requiresPasscode: Bool { shouldReadPrivateFiles }
    
    private let fileName: String?
    private let fileIndex: Int?
    
    public init(fileName: String) {
        self.fileName = fileName
        self.fileIndex = nil
    }
    
    public init(fileIndex: Int) {
        self.fileIndex = fileIndex
        self.fileName = nil
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion.doubleValue < 3.34 {
            return .notSupportedFirmwareVersion
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.interactionMode, value: FileDataMode.readFileHash)
        
        if let fileName = self.fileName {
            try tlvBuilder.append(.fileTypeName, value: fileName)
        }
        
        if let fileIndex = self.fileIndex {
            try tlvBuilder.append(.fileIndex, value: fileIndex)
        }
        
        if shouldReadPrivateFiles {
            try tlvBuilder.append(.pin2, value: environment.passcode.value)
        }
        
        return CommandApdu(.readFileData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadFileChecksumResponse {
        guard let tlv = apdu.getTlvData() else {
            throw TangemSdkError.deserializeApduFailed
        }
        let decoder = TlvDecoder(tlv: tlv)
        return ReadFileChecksumResponse(cardId: try decoder.decode(.cardId),
                                        checksum: try decoder.decode(.codeHash),
                                        fileIndex: try decoder.decode(.fileIndex))
    }
}
