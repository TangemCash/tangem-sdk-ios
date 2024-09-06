//
//  TerminalKeysService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Service for manage keypair, used for Linked Terminal feature. Can be disabled by legacyMode or manually
public class TerminalKeysService {
    let secureStorage = SecureStorage()
    
    /// Retrieve generated keys from keychain if they exist. Generate new and store in Keychain otherwise
    public lazy var keys: KeyPair?  = {
        guard let privateKey = try? secureStorage.get(.terminalPrivateKey),
              let publicKey = try? secureStorage.get(.terminalPublicKey) else {
            
            if let newKeys = try? Secp256k1Utils().generateKeyPair() {
                try? secureStorage.store(newKeys.privateKey, forKey: .terminalPrivateKey)
                try? secureStorage.store(newKeys.publicKey, forKey: .terminalPublicKey)
                return newKeys
            }
            
            return nil
        }
        
        return KeyPair(privateKey: privateKey, publicKey: publicKey)
    }()
}
