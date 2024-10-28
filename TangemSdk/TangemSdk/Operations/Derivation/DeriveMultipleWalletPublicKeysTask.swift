//
//  DeriveMultipleWalletPublicKeysTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 17.12.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public class DeriveMultipleWalletPublicKeysTask: CardSessionRunnable {
    public typealias Response = [Data: DerivedKeys]
    
    private let derivations: Array<(Data,[DerivationPath])>
    private var response: Response = .init()
    
    public init(_ derivations: [Data: [DerivationPath]]) {
        self.derivations = derivations.reduce(into: []) { result, item in
            result.append((item.key, item.value))
        }
    }
    
    deinit {
        Log.debug("DeriveMultipleWalletPublicKeysTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Response>) {
        self.derive(index: 0, in: session, completion: completion)
    }
    
    private func derive(index: Int, in session: CardSession, completion: @escaping CompletionResult<Response>) {
        if index == derivations.count {
            completion(.success(response))
            return
        }
        
        let derivation = derivations[index]
        let task = DeriveWalletPublicKeysTask(walletPublicKey: derivation.0, derivationPaths: derivation.1)
        task.run(in: session) { result in
            switch result {
            case .success(let derivedKeys):
                self.response[derivation.0] = derivedKeys
                self.derive(index: index + 1, in: session, completion: completion)
            case .failure(let error):
                if self.response.isEmpty {
                    completion(.failure(error))
                } else {
                    // return  partial response
                    completion(.success(self.response))
                }
            }
        }
    }
}
