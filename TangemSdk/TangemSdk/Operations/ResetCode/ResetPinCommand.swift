//
//  ResetPinCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

final class ResetPinCommand: Command {
    var requiresPasscode: Bool { return false }
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let accessCode: Data
    private let passcode: Data
    
    init(accessCode: Data, passcode: Data) {
        self.accessCode = accessCode
        self.passcode = passcode
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .notSupportedFirmwareVersion
        }
        
        guard let backupStatus = card.backupStatus,
              backupStatus.isActive else {
            return TangemSdkError.noActiveBackup
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.newPin, value: accessCode)
            .append(.newPin2, value: passcode)
            .append(.codeHash, value: (accessCode + passcode).getSha256())
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        return CommandApdu(.setPin, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
