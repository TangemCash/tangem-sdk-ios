//
//  DeriveWalletPublicKeyTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 05.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public class DeriveWalletPublicKeyTask: CardSessionRunnable {
    private let walletPublicKey: Data
    private let derivationPath: DerivationPath
    
    /// Derive wallet  public key according to BIP32 (Private parent key → public child key).
    /// Warning: Only `secp256k1` and `ed25519` (BIP32-Ed25519 scheme) curves supported
    /// - Parameters:
    ///   - walletPublicKey: Seed public key.
    ///   - derivationPath: Derivation path
    public init(walletPublicKey: Data, derivationPath: DerivationPath) {
        self.walletPublicKey = walletPublicKey
        self.derivationPath = derivationPath
    }
    
    deinit {
        Log.debug("DeriveWalletPublicKeyTask deinit")
    }
    
       
    public func run(in session: CardSession, completion: @escaping CompletionResult<ExtendedPublicKey>) {
        guard let wallet = session.environment.card?.wallets[walletPublicKey] else {
            completion(.failure(TangemSdkError.walletNotFound))
            return
        }
        
        guard wallet.curve.supportsDerivation else {
            completion(.failure(TangemSdkError.unsupportedCurve))
            return
        }

        if case .ed25519_slip0010 = wallet.curve,
           derivationPath.nodes.contains(where: { !$0.isHardened }) {
            completion(.failure(TangemSdkError.nonHardenedDerivationNotSupported))
            return
        }
        
        let readWallet = ReadWalletCommand(walletIndex: wallet.index, derivationPath: derivationPath)
        readWallet.run(in: session) { result in
            switch result {
            case .success(let response):
                guard let chainCode = response.wallet.chainCode else {
                    completion(.failure(.cardError))
                    return
                }
                
                let childKey = ExtendedPublicKey(publicKey: response.wallet.publicKey, chainCode: chainCode)
                session.environment.card?.wallets[self.walletPublicKey]?.derivedKeys[self.derivationPath] = childKey
                completion(.success(childKey))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
