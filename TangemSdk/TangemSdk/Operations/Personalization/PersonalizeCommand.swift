//
//  PersonalizeCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 23.06.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Command available on SDK cards only
/// Personalization is an initialization procedure, required before starting using a card.
/// During this procedure a card setting is set up.
/// During this procedure all data exchange is encrypted.
/// - Warning: Command available only for cards with COS 3.34 and higher. Legacy devices not supported.
public class PersonalizeCommand: Command {
    public var preflightReadMode: PreflightReadMode { .none }
    
    var requiresPasscode: Bool { false }
    
    private let config: CardConfig
    private let issuer: Issuer
    private let manufacturer: Manufacturer
    private let acquirer: Acquirer?
    
    private lazy var devPersonalizationKey: Data = {
        return "1234".sha256().prefix(32)
    }()
    
    /// Default initializer
    /// - Parameters:
    ///   - config:  is a configuration file with all the card settings that are written on the card during personalization.
    ///   - issuer: Issuer is a third-party team or company wishing to use Tangem cards.
    ///   - manufacturer: Tangem Card Manufacturer.
    ///   - acquirer: Acquirer is a trusted third-party company that operates proprietary
    ///   (non-EMV) POS terminal infrastructure and transaction processing back-end.
    public init(config: CardConfig, issuer: Issuer, manufacturer: Manufacturer, acquirer: Acquirer? = nil) {
        self.config = config
        self.issuer = issuer
        self.manufacturer = manufacturer
        self.acquirer = acquirer
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let read = PreflightReadTask(readMode: .readCardOnly, filter: nil) //We have to run preflight read ourseleves to catch the notPersonalized error
        read.run(in: session) { readResult in
            switch readResult {
            case .success:
                completion(.failure(.alreadyPersonalized))
            case .failure(let error):
                if case .notPersonalized = error {
                    self.runPersonalize(in: session, completion: completion)
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        return try CommandApdu(.personalize, tlv: serializePersonalizationData(environment: environment, config: config))
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> Card {
        let decoder = try CardDeserializer.getDecoder(with: environment, from: apdu)
        let cardDataDecoder = try CardDeserializer.getCardDataDecoder(with: environment, from: decoder.tlv)
        
        let isAccessCodeSet = config.pin != UserCodeType.accessCode.defaultValue
        return try CardDeserializer(allowNotPersonalized: true)
            .deserialize(isAccessCodeSetLegacy: isAccessCodeSet,
                         decoder: decoder,
                         cardDataDecoder: cardDataDecoder)
    }
    
    private func runPersonalize(in session: CardSession, completion: @escaping CompletionResult<Card>) {
        let encryptionMode = session.environment.encryptionMode
        let encryptionKey = session.environment.encryptionKey
        session.environment.encryptionMode = .none
        session.environment.encryptionKey = devPersonalizationKey
        transceive(in: session) { result in
            session.environment.encryptionMode = encryptionMode
            session.environment.encryptionKey = encryptionKey
            completion(result)
        }
    }
    
    private func serializePersonalizationData(environment: SessionEnvironment, config: CardConfig) throws -> Data {
        guard let cardId = config.createCardId() else {
            throw TangemSdkError.serializeCommandError
        }
        
        let cardData = config.cardData.createPersonalizationCardData()
        let createWallet: Bool = config.createWallet != 0
        
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: cardId)
            .append(.curveId, value: config.curveID)
            .append(.maxSignatures, value: config.maxSignatures ?? Int(UInt32.max))
            .append(.signingMethod, value: config.signingMethod)
            .append(.settingsMask, value: config.createSettingsMask())
            .append(.pauseBeforePin2, value: config.pauseBeforePin2 / 10)
            .append(.cvc, value: config.cvc.data(using: .utf8))
            .append(.createWalletAtPersonalize, value: createWallet)
            .append(.ndefData, value: serializeNdef(config))
            .append(.newPin, value: config.pin.sha256())
            .append(.newPin2, value: config.pin2.sha256())
            .append(.issuerPublicKey, value: issuer.dataKeyPair.publicKey)
            .append(.issuerTransactionPublicKey, value: issuer.transactionKeyPair.publicKey)
            .append(.cardData, value: try serializeCardData(environment: environment, cardId: cardId, cardData: cardData))
        
        if let pin3 = config.pin3?.sha256() {
            try tlvBuilder.append(.newPin3, value: pin3)
        }
        
        if let hexCrExKey = config.hexCrExKey {
            try tlvBuilder.append(.crExKey, value: hexCrExKey)
        }
        
        if let walletsCount = config.walletsCount {
            try tlvBuilder.append(.walletsCount, value: walletsCount)
        }
        
        if let acquirer = acquirer {
            try tlvBuilder.append(.acquirerPublicKey, value: acquirer.keyPair.publicKey)
        }
        
        return tlvBuilder.serialize()
    }
    
    private func serializeNdef(_ config: CardConfig) throws -> Data {
        guard !config.ndefRecords.isEmpty else {
            return Data()
        }
        
        return try NdefEncoder(ndefRecords: config.ndefRecords,
                               useDynamicNdef: config.useDynamicNDEF ?? false)
            .encode()
    }
    
    private func serializeCardData(environment: SessionEnvironment, cardId: String, cardData: CardData) throws -> Data {
        let signature = try Secp256k1Utils().sign(Data(hexString: cardId), with: manufacturer.keyPair.privateKey)
       
        let tlvBuilder = try TlvBuilder()
            .append(.batchId, value: cardData.batchId)
            .append(.productMask, value: cardData.productMask)
            .append(.manufactureDateTime, value: cardData.manufactureDateTime)
            .append(.issuerName, value: issuer.id)
            .append(.blockchainName, value: cardData.blockchainName)
            .append(.cardIDManufacturerSignature, value: signature)
        
        if cardData.tokenSymbol != nil {
            try tlvBuilder
                .append(.tokenSymbol, value: cardData.tokenSymbol)
                .append(.tokenContractAddress, value: cardData.tokenContractAddress)
                .append(.tokenDecimal, value: cardData.tokenDecimal)
        }
        
        return tlvBuilder.serialize()
    }
}
