//
//  LinkBackupCardsCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `LinkBackupCardsCommand`.
struct LinkBackupCardsResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let attestSignature: Data
}

final class LinkBackupCardsCommand: Command {
    var requiresPasscode: Bool { return true }
    
    private let backupCards: [BackupCard]
    private let accessCode: Data
    private let passcode: Data

    init(backupCards: [BackupCard], accessCode: Data, passcode: Data) {
        self.backupCards = backupCards
        self.accessCode = accessCode
        self.passcode = passcode
    }
    
    deinit {
        Log.debug("LinkBackupCardsCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .backupFailedFirmware
        }
        
        if !card.settings.isBackupAllowed {
            return .backupNotAllowed
        }
        
        if card.wallets.isEmpty {
            return .backupFailedEmptyWallets
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<LinkBackupCardsResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card?.backupStatus = .cardLinked(cardsCount: self.backupCards.count)
                session.environment.card?.settings.isSettingAccessCodeAllowed = true
                session.environment.card?.settings.isSettingPasscodeAllowed = true
                session.environment.card?.settings.isRemovingUserCodesAllowed = false
                
                session.environment.accessCode = UserCode(.accessCode, value: self.accessCode)
                session.environment.passcode = UserCode(.passcode, value: self.passcode)
                
                let isAccessCodeSet = session.environment.isUserCodeSet(.accessCode)
                let isPasscodeSet = session.environment.isUserCodeSet(.passcode)
                
                session.environment.card?.isAccessCodeSet = isAccessCodeSet
                session.environment.card?.isPasscodeSet = isPasscodeSet
                completion(.success(response))
            case .failure(let error):
                switch error {
                case .accessCodeRequired,
                     .passcodeRequired:
                    session.environment.accessCode = UserCode(.accessCode, value: self.accessCode)
                    session.environment.passcode = UserCode(.passcode, value: self.passcode)
                    self.run(in: session, completion: completion)
                default:
                    completion(.failure(error))
                }
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.backupCount, value: backupCards.count)
            .append(.newPin, value: accessCode)
            .append(.newPin2, value: passcode)
        
        for (index, card) in backupCards.enumerated() {
            guard let certificate = card.certificate else {
                throw TangemSdkError.certificateSignatureRequired
            }

            let builder = try TlvBuilder()
                .append(.fileIndex, value: index)
                .append(.backupCardLinkingKey, value: card.linkingKey)
                .append(.certificate, value: certificate)
                .append(.cardSignature, value: card.attestSignature)
            
            try tlvBuilder.append(.backupCardLink, value: builder.serialize())
        }
        
        return CommandApdu(.linkBackupCards, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> LinkBackupCardsResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return LinkBackupCardsResponse(cardId: try decoder.decode(.cardId),
                                       attestSignature: try decoder.decode(.backupAttestSignature))
    }
}
