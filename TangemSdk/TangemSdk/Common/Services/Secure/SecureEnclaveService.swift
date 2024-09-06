//
//  SecureEnclaveService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

struct SecureEnclaveService {
    private let storage = SecureStorage()
    
    func sign(data: Data) throws -> Data {
        let key = try makeOrRestoreKey()
        return try key.signature(for: data).rawRepresentation
    }
    
    func verify(signature: Data, message: Data) throws -> Bool {
        let key = try makeOrRestoreKey()
        let signature = try P256.Signing.ECDSASignature(rawRepresentation: signature)
        return key.publicKey.isValidSignature(signature, for: message)
    }
    
    private func makeOrRestoreKey() throws -> SecureEnclave.P256.Signing.PrivateKey {
        if let restoredKey: SecureEnclave.P256.Signing.PrivateKey = try storage.readKey(.secureEnclaveP256Key) {
            return restoredKey
        }
        
        let accessControl = SecAccessControlCreateWithFlags(nil,
                                                            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                                                            [],
                                                            nil)!
        
        let key = try SecureEnclave.P256.Signing.PrivateKey(compactRepresentable: true,
                                                            accessControl: accessControl,
                                                            authenticationContext: nil)
        try storage.storeKey(key, forKey: .secureEnclaveP256Key)
        return key
    }
}
