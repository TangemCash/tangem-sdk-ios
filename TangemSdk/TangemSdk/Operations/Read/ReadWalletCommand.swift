//
//  ReadWalletCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

struct ReadWalletResponse: JSONStringConvertible {
    let cardId: String
    let wallet: Card.Wallet
}

/// Read single wallet on card. This command executes before interacting with specific wallet to retrieve information about it and perform prechecks
class ReadWalletCommand: Command {
    
    var preflightReadMode: PreflightReadMode { .readCardOnly }
    
    private let walletIndex: Int
    private let derivationPath: DerivationPath?
    
    init(walletIndex: Int, derivationPath: DerivationPath? = nil) {
        self.walletIndex = walletIndex
        self.derivationPath = derivationPath
    }
    
    deinit {
        Log.debug("ReadWalletCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .multiwalletAvailable {
            return .notSupportedFirmwareVersion
        }
        
        if derivationPath != nil  && !card.settings.isHDWalletAllowed {
            return .hdWalletDisabled
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadWalletResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                completion(.success(response))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.interactionMode, value: ReadMode.wallet)
            .append(.cardId, value: environment.card?.cardId)
            .append(.walletIndex, value: walletIndex)
        
        if let derivationPath = derivationPath {
            try tlvBuilder.append(.walletHDPath, value:  derivationPath)
        }
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadWalletResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        guard let wallet = try? WalletDeserializer(isDefaultPermanentWallet: card.settings.isPermanentWallet)
                .deserializeWallet(from: decoder) else {
            throw TangemSdkError.walletNotFound
        }
        
        return ReadWalletResponse(cardId: try decoder.decode(.cardId), wallet: wallet)
    }
}
