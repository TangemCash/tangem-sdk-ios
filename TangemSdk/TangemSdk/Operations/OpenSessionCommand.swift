//
//  OpenSessionCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 22.05.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation


struct OpenSessionResponse {
    let sessionKeyB: Data
    let uid: Data?
}

/// In case of encrypted communication, App should setup a session before calling any further command.
/// [OpenSessionCommand] generates secret session_key that is used by both host and card
/// to encrypt and decrypt commands’ payload.
class OpenSessionCommand: ApduSerializable {
    private let sessionKeyA: Data
    
    init(sessionKeyA: Data) {
        self.sessionKeyA = sessionKeyA
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.sessionKeyA, value: sessionKeyA)
        
        let p2 = environment.encryptionMode == .strong ? EncryptionMode.strong.byteValue : EncryptionMode.fast.byteValue
        return CommandApdu(ins: Instruction.openSession.rawValue, p2: p2, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> OpenSessionResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        return OpenSessionResponse(sessionKeyB: try decoder.decode(.sessionKeyB),
                                   uid: try decoder.decode(.uid))
    }
}


protocol EncryptionHelper {
    var keyA: Data {get}
    func generateSecret(keyB: Data) throws -> Data
}

class EncryptionHelperFactory {
    static func make(for mode: EncryptionMode) throws -> EncryptionHelper {
        switch mode {
        case .fast:
            return try FastEncryptionHelper()
        case .strong:
            return try StrongEncryptionHelper()
        case .none:
            fatalError("Cannot make EncryptionHelper for EncryptionMode NONE")
        }
    }
}

final class FastEncryptionHelper: EncryptionHelper {
    let keyA: Data
    
    init() throws {
        keyA = try CryptoUtils.generateRandomBytes(count: 16)
    }
    
    func generateSecret(keyB: Data) throws -> Data {
        return keyA + keyB
    }
}

final class StrongEncryptionHelper: EncryptionHelper {
    let keyA: Data
    
    private let keyPair: KeyPair
    private let secp256k1 = Secp256k1Utils()
    
    init() throws {
        let keyPair = try secp256k1.generateKeyPair()
        self.keyPair = keyPair
        self.keyA = keyPair.publicKey
    }
    
    func generateSecret(keyB: Data) throws -> Data {
        return try secp256k1.getSharedSecret(privateKey: keyPair.privateKey, publicKey: keyB)
    }
}
