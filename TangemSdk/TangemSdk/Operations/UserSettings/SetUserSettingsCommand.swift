//
//  SetUserSettingsCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 28.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `SetUserSettingsCommand`. COS v.6.16+
struct SetUserSettingsCommandResponse: JSONStringConvertible {
    /// Unique Tangem card ID number.
    let cardId: String
    /// The mask that was set
    let settings: Card.UserSettings
}

/// Set user serrings on a card. COS v.6.16+
class SetUserSettingsCommand: Command {
    var preflightReadMode: PreflightReadMode { .readCardOnly }

    private let settings: Card.UserSettings

    init(settings: Card.UserSettings) {
        self.settings = settings
    }

    deinit {
        Log.debug("SetUserSettingsCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard card.firmwareVersion >= .keysImportAvailable else {
            return TangemSdkError.notSupportedFirmwareVersion
        }

        return nil
    }

    func run(in session: CardSession, completion: @escaping CompletionResult<SetUserSettingsCommandResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                session.environment.card?.userSettings = response.settings
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.userSettingsMask, value: settings.mask)

        return CommandApdu(.setUserSettings, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> SetUserSettingsCommandResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }

        let decoder = TlvDecoder(tlv: tlv)
        let mask: UserSettingsMask = try decoder.decode(.userSettingsMask)
        return SetUserSettingsCommandResponse(cardId: try decoder.decode(.cardId), settings: .init(from: mask))
    }
}
