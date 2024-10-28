//
//  GetEntropyCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `GetEntropyCommand`.
public struct GetEntropyResponse: JSONStringConvertible {
    /// Unique Tangem card ID number.
    public let cardId: String
    /// Random bytes
    public let data: Data
}

/// Get entropy from the card
public class GetEntropyCommand: Command {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }

    public init() {}

    deinit {
        Log.debug("GetEntropyCommand deinit")
    }

    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard card.firmwareVersion >= .keysImportAvailable else {
            return TangemSdkError.notSupportedFirmwareVersion
        }

        return nil
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.cardId, value: environment.card?.cardId)

        return CommandApdu(.getEntropy, tlv: tlvBuilder.serialize())
    }

    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> GetEntropyResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }

        let decoder = TlvDecoder(tlv: tlv)

        return GetEntropyResponse(cardId: try decoder.decode(.cardId),
                                  data: try decoder.decode(.issuerData))
    }
}
