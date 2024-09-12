//
//  ReadBackupDataCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 24.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

// Response from the Tangem card after `ReadBackupDataCommand`.
struct ReadBackupDataResponse {
    /// Unique Tangem card ID number
    fileprivate(set) var cardId: String = ""
    fileprivate(set) var data: [EncryptedBackupData] = []
    
    fileprivate mutating func update(with response: PartialReadBackupDataResponse) {
        cardId = response.cardId
        data.append(response.data)
    }
}

// Response from the Tangem card after `ReadBackupDataCommand`.
struct PartialReadBackupDataResponse {
    /// Unique Tangem card ID number
    let cardId: String
    let index: Int
    let data: EncryptedBackupData
}

final class ReadBackupDataCommand: Command {
    var requiresPasscode: Bool { return false }
    
    private let backupCardLinkingKey: Data
    private let accessCode: Data
    
    private var aggregatedResponse: ReadBackupDataResponse = .init()
    private var readIndex: Int = 0
    
    init(backupCardLinkingKey: Data, accessCode: Data) {
        self.backupCardLinkingKey = backupCardLinkingKey
        self.accessCode = accessCode
    }
    
    deinit {
        Log.debug("ReadBackupDataCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .backupAvailable {
            return .backupFailedFirmware
        }
        
        if !card.settings.isBackupAllowed {
            return .backupNotAllowed
        }
        
        if card.backupStatus == .noBackup {
            return .backupFailedCardNotLinked
        }
        
        if card.wallets.isEmpty {
            return .backupFailedEmptyWallets
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<ReadBackupDataResponse>) {
        readData(in: session) { result in
            switch result {
            case .success:
                if case let .cardLinked(cardsCount: cardsCount) = session.environment.card?.backupStatus {
                    session.environment.card?.backupStatus = .active(cardsCount: cardsCount)

                    let walletsCount = session.environment.card?.wallets.count ?? 0
                    for index in 0..<walletsCount {
                        session.environment.card?.wallets[index].hasBackup = true
                    }
                }
                completion(.success(self.aggregatedResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readData(in session: CardSession, completion: @escaping CompletionResult<Void>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        transceive(in: session) { result in
            switch result {
            case .success(let partialResponse):
                self.aggregatedResponse.update(with: partialResponse)
                
                if partialResponse.index == card.settings.maxWalletsCount - 1 {
                    completion(.success(()))
                } else {
                    self.readIndex = partialResponse.index + 1
                    self.readData(in: session, completion: completion)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: accessCode)
            .append(.backupCardLinkingKey, value: backupCardLinkingKey)
            .append(.walletIndex, value: readIndex)
        
        return CommandApdu(.readBackupData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> PartialReadBackupDataResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        
        return PartialReadBackupDataResponse(cardId: try decoder.decode(.cardId),
                                             index: try decoder.decode(.walletIndex),
                                             data: EncryptedBackupData (data: try decoder.decode(.issuerData),
                                                                        salt: try decoder.decode(.salt)))
    }
}

