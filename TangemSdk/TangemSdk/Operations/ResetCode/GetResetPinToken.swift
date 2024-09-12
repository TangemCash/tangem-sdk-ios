//
//  GetResetPinToken.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

final class GetResetPinTokenCommand: Command {
    var requiresPasscode: Bool { return false }
    var preflightReadMode: PreflightReadMode { .readCardOnly }

    deinit {
        Log.debug("GetResetPinTokenCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .notSupportedFirmwareVersion
        }
        
        guard let backupStatus = card.backupStatus,
              backupStatus.isActive else {
            return TangemSdkError.noActiveBackup
        }

        guard card.userSettings.isUserCodeRecoveryAllowed else {
            return TangemSdkError.userCodeRecoveryDisabled
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.interactionMode, value: AuthorizeMode.tokenGet)
        
        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ResetPinCard {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        guard let isAccessCodeSet = environment.card?.isAccessCodeSet,
              let isPasscodeSet = environment.card?.isPasscodeSet else {
            throw TangemSdkError.missingPreflightRead
        }
        
        let card = ResetPinCard(cardId: try decoder.decode(.cardId),
                                backupKey: try decoder.decode(.primaryCardLinkingKey),
                                attestSignature: try decoder.decode(.backupAttestSignature),
                                token: try decoder.decode(.challenge),
                                isAccessCodeSet: isAccessCodeSet,
                                isPasscodeSet: isPasscodeSet)
        
        return card
    }
}
