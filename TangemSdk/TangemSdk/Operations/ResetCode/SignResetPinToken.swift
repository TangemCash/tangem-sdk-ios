//
//  SignResetPinToken.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03.09.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

final class SignResetPinTokenCommand: Command {
    var requiresPasscode: Bool { return false }
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let resetPinCard: ResetPinCard
    
    init(resetPinCard: ResetPinCard) {
        self.resetPinCard = resetPinCard
    }
    
    deinit {
        Log.debug("SignResetPinTokenCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .resetPinWrongCard(internalCode: TangemSdkError.notSupportedFirmwareVersion.code)
        }
        
        guard let backupStatus = card.backupStatus, backupStatus.isActive else {
            return .resetPinWrongCard(internalCode: TangemSdkError.noActiveBackup.code)
        }
        
        if card.cardId == resetPinCard.cardId {
            return .resetPinWrongCard()
        }

        guard card.userSettings.isUserCodeRecoveryAllowed else {
            return TangemSdkError.userCodeRecoveryDisabled
        }

        return nil
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        if case .invalidParams = error {
            return .resetPinWrongCard()
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.interactionMode, value: AuthorizeMode.tokenSign)
            .append(.challenge, value: resetPinCard.token)
            .append(.primaryCardLinkingKey, value: resetPinCard.backupKey)
            .append(.backupAttestSignature, value: resetPinCard.attestSignature)
        
        return CommandApdu(.authorize, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ConfirmationCard {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        let card = ConfirmationCard(cardId: try decoder.decode(.cardId),
                                    backupKey: try decoder.decode(.backupCardLinkingKey),
                                    salt: try decoder.decode(.salt),
                                    authorizeSignature: try decoder.decode(.backupAttestSignature))
        
        return card
    }
}
