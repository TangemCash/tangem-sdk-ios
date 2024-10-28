//
//  StartBackupCardLinkingCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

final class StartBackupCardLinkingCommand: Command {
    var requiresPasscode: Bool { return false }

    private let primaryCardLinkingKey: Data

    init(primaryCardLinkingKey: Data) {
        self.primaryCardLinkingKey = primaryCardLinkingKey
    }

    deinit {
        Log.debug("StartBackupCardLinkingCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .backupFailedFirmware
        }

        if !card.settings.isBackupAllowed {
            return .backupNotAllowed
        }

        guard let backupStatus = card.backupStatus, backupStatus.canBackup else {
            return TangemSdkError.backupFailedAlreadyCreated
        }

        if !card.wallets.isEmpty {
            return .backupFailedNotEmptyWallets(cardId: card.cardId)
        }

        return nil
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.primaryCardLinkingKey, value: primaryCardLinkingKey)

        return CommandApdu(.startBackupCardLinking, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> BackupCard {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }

        guard let card = environment.card else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)

        return BackupCard(
            cardId: try decoder.decode(.cardId),
            cardPublicKey: card.cardPublicKey,
            firmwareVersion: card.firmwareVersion,
            batchId: card.batchId,
            linkingKey: try decoder.decode(.backupCardLinkingKey),
            attestSignature: try decoder.decode(.cardSignature)
        )
    }
}
