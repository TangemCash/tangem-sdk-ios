//
//  UserCodeRepository.swift
//  TangemSdk
//
//  Created by Andrey Chukavin on 13.05.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import LocalAuthentication

@available(iOS 13.0, *)
public class UserCodeRepository {
    var isEmpty: Bool {
        getCards().isEmpty
    }
    
    private let secureStorage: SecureStorage = .init()
    private let biometricsStorage: BiometricsStorage  = .init()
    private var userCodes: [String: UserCode] = [:]
    
    private lazy var context: LAContext = LAContext.default
    
    public init() {}
    
    deinit {
        Log.debug("UserCodeRepository deinit")
    }
    
    func save(_ userCode: UserCode, for cardIds: [String], completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard BiometricsUtil.isAvailable else {
            completion(.failure(.biometricsUnavailable))
            return
        }
        
        guard updateCodesIfNeeded(with: userCode, for: cardIds) else {
            completion(.success(())) //Nothing changed. Return
            return
        }
        
        do {
            let data = try JSONEncoder().encode(userCodes)
            
            let result = biometricsStorage.store(data, forKey: .userCodes, context: context)
            switch result {
            case .success:
                self.saveCards()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        } catch {
            Log.error(error)
            completion(.failure(error.toTangemSdkError()))
        }
    }
    
    func save(_ userCode: UserCode, for cardId: String, completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        save(userCode, for: [cardId], completion: completion)
    }
    
    public func clear() {
        do {
            try biometricsStorage.delete(.userCodes)
            try secureStorage.delete(.cardsWithSavedCodes)
        } catch {
            Log.error(error)
        }
    }
    
    func contains(_ cardId: String) -> Bool {
        let savedCards = getCards()
        return savedCards.contains(cardId)
    }
    
    func unlock(completion: @escaping (Result<Void, TangemSdkError>) -> Void) {
        guard BiometricsUtil.isAvailable else {
            completion(.failure(.biometricsUnavailable))
            return
        }
        
        userCodes = .init()
        
        let result = biometricsStorage.get(.userCodes, context: context)
        switch result {
        case .success(let data):
            if let data = data,
               let codes = try? JSONDecoder().decode([String: UserCode].self, from: data) {
                self.userCodes = codes
            }
            completion(.success(()))
        case .failure(let error):
            Log.error(error)
            completion(.failure(error))
        }
    }
    
    func lock() {
        userCodes = .init()
    }
    
    func fetch(for cardId: String) -> UserCode? {
        return userCodes[cardId]
    }
    
    private func updateCodesIfNeeded(with userCode: UserCode, for cardIds: [String]) -> Bool {
        var hasChanges: Bool = false
        
        for cardId in cardIds {
            let existingCode = userCodes[cardId]
            
            if existingCode?.value == userCode.value {
                continue //We already know this code. Ignoring
            }
            
            //We found default code
            if userCode.value == userCode.type.defaultValue.sha256() {
                if existingCode == nil {
                    continue //Ignore default code
                } else {
                    userCodes[cardId] = nil //User deleted the code. We should update the storage
                    hasChanges = true
                }
            } else {
                userCodes[cardId] = userCode //Save a new code
                hasChanges = true
            }
        }
        
        return hasChanges
    }
    
    private func getCards() -> Set<String> {
        if let data = try? secureStorage.get(.cardsWithSavedCodes) {
            return (try? JSONDecoder().decode(Set<String>.self, from: data)) ?? []
        }
        
        return []
    }
    
    private func saveCards() {
        if let data = try? JSONEncoder().encode(Set(userCodes.keys)) {
            try? secureStorage.store(data, forKey: .cardsWithSavedCodes)
        }
    }
}
