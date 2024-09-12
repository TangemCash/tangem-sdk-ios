//
//  ReadWalletsListCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 16/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public struct ReadWalletsListResponse: JSONStringConvertible {
    public let cardId: String
    public let wallets: [Card.Wallet]
}

/// Read all wallets on card.
public class ReadWalletsListCommand: Command {
    public var preflightReadMode: PreflightReadMode { .readCardOnly }

    private var loadedWallets: [Card.Wallet] = []
    private var receivedWalletsCount: Int = 0
    
    public init() {}
    
    deinit {
        Log.debug("ReadWalletsListCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .multiwalletAvailable {
            return .notSupportedFirmwareVersion
        }
        
        return nil
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<ReadWalletsListResponse>) {
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                self.loadedWallets.append(contentsOf: response.wallets)
                
                if self.receivedWalletsCount == 0 && response.wallets.isEmpty {
                    completion(.failure(.cardWithMaxZeroWallets))
                    return
                }
                
                guard self.receivedWalletsCount == session.environment.card?.settings.maxWalletsCount else {
                    self.run(in: session, completion: completion)
                    return
                }
                
                let wallets = self.loadedWallets.sorted(by: { $0.index < $1.index })
                session.environment.card?.wallets = wallets
                
                completion(.success(ReadWalletsListResponse(cardId: response.cardId,
                                                            wallets: wallets)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.interactionMode, value: ReadMode.walletsList)
            .append(.cardId, value: environment.card?.cardId)
        
        if receivedWalletsCount > 0 {
            try tlvBuilder.append(.walletIndex, value: receivedWalletsCount)
        }
        
        return CommandApdu(.read, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadWalletsListResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.unknownError
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let deserializedData = try WalletDeserializer(isDefaultPermanentWallet: card.settings.isPermanentWallet).deserializeWallets(from: decoder)
        receivedWalletsCount += deserializedData.totalReceived
        return ReadWalletsListResponse(cardId: try decoder.decode(.cardId),
                                       wallets: deserializedData.wallets)
    }
}
