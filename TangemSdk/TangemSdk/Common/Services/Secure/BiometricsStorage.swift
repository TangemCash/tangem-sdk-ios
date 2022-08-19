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
@available(iOS 13.0, *)
public class BiometricsStorage {
    private lazy var context: LAContext = {
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 60
        return context
    }()
  
    public init() {}
    
    public func get(_ account: String, context: LAContext? = nil, completion: @escaping (Result<Data?, TangemSdkError>) -> Void) {
        DispatchQueue.global().async {
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
            switch  status {
            case errSecSuccess:
                guard let data = result as? Data else {
                    completion(.success(nil))
                    return
                }
                
                completion(.success(data))
            case errSecItemNotFound:
                completion(.success(nil))
            case errSecUserCanceled:
                completion(.failure(.userCancelled))
            case let status:
                let error = KeyStoreError("Keychain read failed: \(status.message)")
                completion(.failure(error.toTangemSdkError()))
            }
        }
    }
    
    public func store(_ object: Data, forKey account: String, overwrite: Bool = true, context: LAContext? = nil, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: account,
                kSecUseDataProtectionKeychain: true,
                kSecValueData: object,
                kSecAttrAccessControl: self.makeBiometricAccessControl(),
                kSecUseAuthenticationContext: context ?? self.context,
            ]
            
            var status = SecItemAdd(query as CFDictionary, nil)
            
            if status == errSecDuplicateItem && overwrite {
                let searchQuery: [CFString: Any] = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrAccount: account,
                    kSecUseDataProtectionKeychain: true,
                    kSecAttrAccessControl: self.makeBiometricAccessControl(),
                    kSecUseAuthenticationContext: context ?? self.context,
                ]
                
                let attributes = [kSecValueData: object] as [String: Any]
                status = SecItemUpdate(searchQuery as CFDictionary, attributes as CFDictionary)
            }
            
            switch status {
            case errSecSuccess:
                completion(.success(()))
            case errSecUserCanceled:
                completion(.failure(.userCancelled))
            default:
                let error = KeyStoreError("Unable to store item: \(status.message)")
                completion(.failure(error.toTangemSdkError()))
            }
        }
    }
    
    public func delete(_ account : String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain: true,
            kSecAttrAccount: account,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecItemNotFound, errSecSuccess:
            break
        case let status:
            let error = KeyStoreError("Unexpected deletion error: \(status.message)")
            throw error.toTangemSdkError()
        }
    }
    
    func get(_ storageKey: SecureStorageKey, completion: @escaping (Result<Data?, TangemSdkError>) -> Void) {
        get(storageKey.rawValue, completion: completion)
    }
    
    func store(_ object: Data, forKey storageKey: SecureStorageKey, overwrite: Bool = true, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
         store(object, forKey: storageKey.rawValue, completion: completion)
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
