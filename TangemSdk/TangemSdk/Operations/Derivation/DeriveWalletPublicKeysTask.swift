//
//  DeriveWalletPublicKeysTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public class DeriveWalletPublicKeysTask: CardSessionRunnable {
    private let walletPublicKey: Data
    private let derivationPaths: [DerivationPath]
    
    /// Derive multiple wallet  public keys according to BIP32 (Private parent key → public child key).
    /// Warning: Only `secp256k1` and `ed25519` (BIP32-Ed25519 scheme) curves supported
    /// - Parameters:
    ///   - walletPublicKey: Seed public key.
    ///   - derivationPaths: Multiple derivation paths. Repeated items will be ignored.
    public init(walletPublicKey: Data, derivationPaths: [DerivationPath]) {
        self.walletPublicKey = walletPublicKey
        self.derivationPaths = Array(Set(derivationPaths))
    }
    
    deinit {
        Log.debug("DeriveWalletPublicKeysTask deinit")
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<DerivedKeys>) {
        runDerivation(at: 0, keys: [:], in: session, completion: completion)
    }
    
    private func runDerivation(at index: Int, keys: DerivedKeys, in session: CardSession, completion: @escaping CompletionResult<DerivedKeys>) {
        guard index < derivationPaths.count else {
            completion(.success(keys))
            return
        }
        let path = derivationPaths[index]
        let task = DeriveWalletPublicKeyTask(walletPublicKey: walletPublicKey, derivationPath: path)
        task.run(in: session) { result in
            var keys = keys
            
            switch result {
            case .success(let key):
                keys[path] = key
            case .failure(let error):
                Log.error(error)
            }

            self.runDerivation(at: index + 1, keys: keys, in: session, completion: completion)
        }
    }
}
