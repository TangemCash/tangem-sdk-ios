//
//  BiometricsStorage.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 06.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Security
import LocalAuthentication

/// Helper class for Keychain
public class BiometricsStorage {
    private let context = LAContext.default
  
    public init() {}
    
    public func get(_ account: String, context: LAContext? = nil) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true,
            kSecUseAuthenticationContext: context ?? self.context,
        ]
        
        var result: AnyObject?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        Log.debug("BiometricsStorage get - status \(status.message) \(status). Data size \((result as? Data)?.count ?? -1)")
        
        switch  status {
        case errSecSuccess:
            guard let data = result as? Data else {
                return nil
            }
            
            return data
        case errSecItemNotFound:
            return nil
        case errSecUserCanceled:
            throw TangemSdkError.userCancelled
        case let status:
            let error = KeyStoreError("Keychain read failed: \(status.message)")
            throw error
        }
    }
    
    public func store(_ object: Data, forKey account: String, overwrite: Bool = true, context: LAContext? = nil) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: account,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: object,
            kSecAttrAccessControl: self.makeBiometricAccessControl(),
            kSecUseAuthenticationContext: context ?? self.context,
        ]
        
        var status = SecItemAdd(query as CFDictionary, nil)
        
        Log.debug("BiometricsStorage set - status \(status.message) \(status)")
        
        if status == errSecDuplicateItem && overwrite {
            let searchQuery: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: account,
                kSecUseDataProtectionKeychain: true,
                kSecAttrAccessControl: self.makeBiometricAccessControl(),
                kSecUseAuthenticationContext: context ?? self.context
            ]
            
            let attributes = [kSecValueData: object] as [String: Any]
            status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)
    
            Log.debug("BiometricsStorage set - overwrite status \(status.message) \(status)")
        }
        
        switch status {
        case errSecSuccess:
            break
        case errSecUserCanceled:
            throw TangemSdkError.userCancelled
        default:
            let error = KeyStoreError("Unable to store item: \(status.message)")
            throw error
        }
    }
    
    public func delete(_ account : String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccount: account,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        Log.debug("BiometricsStorage delete - status \(status.message) \(status)")
        
        switch status {
        case errSecItemNotFound, errSecSuccess:
            break
        case let status:
            let error = KeyStoreError("Unexpected deletion error: \(status.message)")
            throw error.toTangemSdkError()
        }
    }
    
    func get(_ storageKey: SecureStorageKey, context: LAContext? = nil) throws -> Data? {
        try get(storageKey.rawValue, context: context)
    }
    
    func store(_ object: Data, forKey storageKey: SecureStorageKey, overwrite: Bool = true, context: LAContext? = nil) throws {
         try store(object, forKey: storageKey.rawValue, overwrite: overwrite, context: context)
    }
    
    func delete(_ storageKey: SecureStorageKey) throws {
        try delete(storageKey.rawValue)
    }
    
    private func makeBiometricAccessControl() -> SecAccessControl {
        return SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            nil
        )!
    }
}
