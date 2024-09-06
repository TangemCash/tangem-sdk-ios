//
//  ChangeFileSettingsCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Command for updating file settings
public final class ChangeFileSettingsCommand: Command {
    public var requiresPasscode: Bool { true }
    
    private let fileIndex: Int
    private let newPermissions: FileVisibility
    
    public init(fileIndex: Int, newPermissions: FileVisibility) {
        self.fileIndex = fileIndex
        self.newPermissions = newPermissions
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .filesAvailable {
            return .notSupportedFirmwareVersion
        }
        
        if !card.settings.isFilesAllowed {
            return .filesDisabled
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let card = environment.card else {
           throw TangemSdkError.missingPreflightRead
        }
        
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.interactionMode, value: FileDataMode.changeFileSettings)
            .append(.fileIndex, value: fileIndex)
            .append(.fileSettings, value: newPermissions.serializeValue(for: card.firmwareVersion))
        
        return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        guard let tlv = apdu.getTlvData() else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
