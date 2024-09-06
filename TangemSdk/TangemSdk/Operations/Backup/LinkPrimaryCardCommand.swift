//
//  LinkPrimaryCardCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `LinkPrimaryCardCommand`.
struct LinkPrimaryCardResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let backupStatus: Card.BackupRawStatus
}

final class LinkPrimaryCardCommand: Command {
    var requiresPasscode: Bool { return true }
    
    private let primaryCard: PrimaryCard
    private let backupCards: [BackupCard]
    private let attestSignature: Data
    private let accessCode: Data
    private let passcode: Data
    
    init(primaryCard: PrimaryCard, backupCards: [BackupCard], attestSignature: Data, accessCode: Data, passcode: Data) {
        self.primaryCard = primaryCard
        self.backupCards = backupCards
        self.attestSignature = attestSignature
        self.accessCode = accessCode
        self.passcode = passcode
    }
    
    deinit {
        Log.debug("LinkPrimaryCardCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .backupFailedFirmware
        }
        
        if !card.settings.isBackupAllowed {
            return .backupNotAllowed
        }
        
        if !card.wallets.isEmpty {
            return .backupFailedNotEmptyWallets(cardId: card.cardId)
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<LinkPrimaryCardResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.accessCode = UserCode(.accessCode, value: self.accessCode)
                session.environment.passcode = UserCode(.passcode, value: self.passcode)
                
                let isAccessCodeSet = session.environment.isUserCodeSet(.accessCode)
                let isPasscodeSet = session.environment.isUserCodeSet(.passcode)
                
                session.environment.card?.isAccessCodeSet = isAccessCodeSet
                session.environment.card?.isPasscodeSet = isPasscodeSet
                self.complete(response: response, session: session, completion: completion)
            case .failure(let error):
                switch error {
                case .accessCodeRequired, .passcodeRequired:
                    if let cardId = session.environment.card?.cardId {
                        self.complete(response: LinkPrimaryCardResponse(cardId: cardId,
                                                                        backupStatus: .cardLinked),
                                      session: session,
                                      completion: completion)
                        return
                    }
                    completion(.failure(error))
                default:
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func complete(response: LinkPrimaryCardResponse, session: CardSession, completion: @escaping CompletionResult<LinkPrimaryCardResponse>) {
        session.environment.card?.backupStatus = try? Card.BackupStatus(from: response.backupStatus, cardsCount: self.backupCards.count)
        session.environment.card?.settings.isSettingAccessCodeAllowed = true
        session.environment.card?.settings.isSettingPasscodeAllowed = true
        session.environment.card?.settings.isRemovingUserCodesAllowed = false
        completion(.success(response))
    }
    
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let certificate = primaryCard.certificate else {
            throw TangemSdkError.certificateSignatureRequired
        }

        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.primaryCardLinkingKey, value: primaryCard.linkingKey)
            .append(.certificate, value: certificate)
            .append(.backupAttestSignature, value: attestSignature)
            .append(.newPin, value: accessCode)
            .append(.newPin2, value: passcode)
        
        for (index, card) in backupCards.enumerated() {
            let builder = try TlvBuilder()
                .append(.fileIndex, value: index)
                .append(.backupCardLinkingKey, value: card.linkingKey)
            
            try tlvBuilder.append(.backupCardLink, value: builder.serialize())
        }
        
        return CommandApdu(.linkPrimaryCard, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> LinkPrimaryCardResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return LinkPrimaryCardResponse(cardId: try decoder.decode(.cardId),
                                       backupStatus: try decoder.decode(.backupStatus))
    }
}
