//
//  GenerateOTPCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27.09.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response from the Tangem card after `GenerateOTPCommand`.
public struct GenerateOTPResponse: JSONStringConvertible {
    /// Unique Tangem card ID number.
    public let cardId: String
    /// Generated  root OTP.
    public let rootOTP: Data
    /// Generated root OTP's counter.
    public let rootOTPCounter: Int
    /// Wallet's public key.
    public let walletPublicKey: Data
}

/// Generate OTP on the card.
public class GenerateOTPCommand: Command {
    public init() {}
    
    deinit {
        Log.debug("GenerateOTPCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard !card.wallets.isEmpty else {
            return TangemSdkError.walletNotFound
        }
        
        return nil
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
        
        return CommandApdu(.generateOTP, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> GenerateOTPResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return GenerateOTPResponse(cardId: try decoder.decode(.cardId),
                                   rootOTP: try decoder.decode(.codeHash),
                                   rootOTPCounter: try decoder.decode(.fileIndex),
                                   walletPublicKey: try decoder.decode(.walletPublicKey))
    }
}
