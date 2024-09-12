//
//  SecureStorageService.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.01.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Security

/// Helper class for Keychain
public struct SecureStorage {
    
    public init() {}
    
    public func get(_ account: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true,
        ]
        
        var result: AnyObject?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        Log.debug("SecureStorage get - status \(status.message) \(status). Data size \((result as? Data)?.count ?? -1)")
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            
            return data
        case errSecItemNotFound:
            return nil
        case let status:
            throw KeyStoreError("Keychain read failed: \(status.message)")
        }
    }
    
    public func store(_ object: Data, forKey account: String, overwrite: Bool = true) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecValueData: object,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        
        var status = SecItemAdd(query as CFDictionary, nil)
        
        Log.debug("SecureStorage set - status \(status.message) \(status)")
        
        if status == errSecDuplicateItem && overwrite {
            let searchQuery: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: account,
            ]
            
            let attributes = [kSecValueData: object] as [String: Any]
            
            status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)
            
            Log.debug("SecureStorage set - overwrite status \(status.message) \(status)")
        }
        
        guard status == errSecSuccess else {
            throw KeyStoreError("Unable to store item: \(status.message)")
        }
    }
    
    public func delete(_ account: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccount: account,
        ]
        
        
        let status = SecItemDelete(query as CFDictionary)

        Log.debug("SecureStorage delete - status \(status.message) \(status)")
        
        switch status {
        case errSecItemNotFound, errSecSuccess: break // Okay to ignore
        case let status:
            throw KeyStoreError("Unexpected deletion error: \(status.message)")
        }
    }
    
    func get(_ storageKey: SecureStorageKey) throws -> Data? {
        try get(storageKey.rawValue)
    }
    
    func store(_ object: Data, forKey storageKey: SecureStorageKey, overwrite: Bool = true) throws  {
       try store(object, forKey: storageKey.rawValue)
    }
    
    func delete(_ storageKey: SecureStorageKey) throws {
        try delete(storageKey.rawValue)
    }
}

extension SecureStorage {
    /// Stores a CryptoKit key in the keychain as a generic password.
    func storeKey<T: GenericPasswordConvertible>(_ key: T, forKey storageKey: SecureStorageKey) throws {
        try store(key.rawRepresentation, forKey: storageKey, overwrite: true)
    }
    
    /// Reads a CryptoKit key from the keychain as a generic password.
    func readKey<T: GenericPasswordConvertible>(_ storageKey: SecureStorageKey) throws -> T? {
        if let data = try get(storageKey) {
            return try T(rawRepresentation: data)
        }
        
        return nil
    }
}
