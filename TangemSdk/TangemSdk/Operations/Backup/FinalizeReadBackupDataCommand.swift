//
//  FinalizeReadBackupDataCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

final class FinalizeReadBackupDataCommand: Command {
    var requiresPasscode: Bool { return false }

    private let accessCode: Data

    init(accessCode: Data) {
        self.accessCode = accessCode
    }

    deinit {
        Log.debug("FinalizeReadBackupDataCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .keysImportAvailable {
            return .backupFailedFirmware
        }

        if !card.settings.isBackupAllowed {
            return .backupNotAllowed
        }

        if card.backupStatus == .noBackup {
            return .backupFailedCardNotLinked
        }

        if card.wallets.isEmpty {
            return .backupFailedEmptyWallets
        }

        return nil
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: accessCode)

        return CommandApdu(.finalizeReadBackupData, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SuccessResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }

        let decoder = TlvDecoder(tlv: tlv)
        return SuccessResponse(cardId: try decoder.decode(.cardId))
    }
}

