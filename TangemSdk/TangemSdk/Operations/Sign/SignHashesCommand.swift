//
//  SignHashesTask.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 21.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
public typealias SignHashesResponse = SignResponse

public final class SignHashesCommand: CardSessionRunnable {
    private let walletPublicKey: Data
    private let hashes: [Data]
    private let derivationPath: DerivationPath?

    /// Default initializer
    /// - Parameters:
    ///   - hashes: Array of transaction hashes. It can be from one or up to ten hashes of the same length.
    ///   - walletPublicKey: Public key of the wallet, using for sign.
    ///   - derivationPath: Derivation path of the wallet. Optional. COS v. 4.28 and higher,
    public init(hashes: [Data], walletPublicKey: Data, derivationPath: DerivationPath? = nil) {
        self.hashes = hashes
        self.walletPublicKey = walletPublicKey
        self.derivationPath = derivationPath
    }

    deinit {
        Log.debug("SignHashesCommand deinit")
    }

    public func run(in session: CardSession, completion: @escaping CompletionResult<SignHashesResponse>) {
        let signCommand = SignCommand(hashes: hashes, walletPublicKey: walletPublicKey, derivationPath: derivationPath)
        signCommand.run(in: session, completion: completion)
    }
}
