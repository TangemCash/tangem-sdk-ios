//
//  AuthorizeResetPinToken.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

final class AuthorizeResetPinTokenCommand: Command {
    var requiresPasscode: Bool { return false }
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let confirmationCard: ConfirmationCard
    
    init(confirmationCard: ConfirmationCard) {
        self.confirmationCard = confirmationCard
    }
    
    deinit {
        Log.debug("AuthorizeResetPinTokenCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .notSupportedFirmwareVersion
        }
        
        guard let backupStatus = card.backupStatus,
              backupStatus.isActive else {
            return TangemSdkError.invalidState
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.interactionMode, value: AuthorizeMode.tokenAuthenticate)
            .append(.salt, value: confirmationCard.salt)
            .append(.backupCardLinkingKey, value: confirmationCard.backupKey)
            .append(.backupAttestSignature, value: confirmationCard.authorizeSignature)
        
        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}
