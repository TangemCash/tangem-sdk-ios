//
//  ReadFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/6/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `ReadFileCommand`
struct ReadFileResponse: JSONStringConvertible {
    var cardId: String
    var size: Int?
    var offset: Int?
    var fileData: Data
    var fileIndex: Int
    var settings: FileSettings?
    var ownerIndex: Int?
    var ownerPublicKey: Data?
    var walletIndex: Int?
    
    fileprivate var isReadComplete: Bool {
        guard let size = self.size else { return true }
        
        return fileData.count == size
    }
    
    fileprivate static var empty: ReadFileResponse {
        return ReadFileResponse(cardId: "",
                                size: nil,
                                offset: nil,
                                fileData: Data(),
                                fileIndex: 0,
                                settings: nil,
                                ownerIndex: nil,
                                ownerPublicKey: nil,
                                walletIndex: nil)
    }
    
    fileprivate mutating func update(with response: ReadFileResponse) {
        self.cardId = response.cardId
        self.fileIndex = response.fileIndex
        
        response.size.map { self.size = $0 }
        response.settings.map { self.settings = $0 }
        response.ownerIndex.map { self.ownerIndex = $0 }
        response.ownerPublicKey.map { self.ownerPublicKey = $0 }
        response.walletIndex.map { self.walletIndex = $0 }
        response.offset.map { self.offset = $0 }
        
        self.fileData += response.fileData
    }
}

/// Command that read single file at specified index. Reading private file will prompt user to input a passcode.
final class ReadFileCommand: Command {
    ///If true, user code or security delay will be requested
    var shouldReadPrivateFiles = false
    
    var requiresPasscode: Bool { shouldReadPrivateFiles }
    
    //Read filters
    private let fileIndex: Int
    private let fileName: String?
    private let walletPublicKey: Data?
    private var walletIndex: Int?

    private var aggregatedResponse: ReadFileResponse = .empty
    
    init(fileIndex: Int, fileName: String? = nil, walletPublicKey: Data? = nil) {
        self.fileIndex = fileIndex
        self.fileName = fileName
        self.walletPublicKey = walletPublicKey
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .filesAvailable {
            return .notSupportedFirmwareVersion
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<File?>) {
        guard let card = session.environment.card else {
            completion(.failure(.missingPreflightRead))
            return
        }
        
        if let walletPublicKey = self.walletPublicKey { //optimization
            self.walletIndex = card.wallets[walletPublicKey]?.index
            
            if self.walletIndex == nil {
                completion(.failure(.walletNotFound))
                return
            }
        }
        
        readFileData(session: session) { result in
            switch result {
            case .success:
                completion(.success(File(response: self.aggregatedResponse)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func readFileData(session: CardSession, completion: @escaping CompletionResult<Void>) {
        transceive(in: session) { (result) in
            switch result {
            case .success(let response):
                self.aggregatedResponse.update(with: response)
                
                if self.aggregatedResponse.isReadComplete {
                    completion(.success(()))
                    return
                }

                self.readFileData(session: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.fileIndex, value: fileIndex)
            .append(.offset, value: self.aggregatedResponse.fileData.count)
        
        if let fileName = self.fileName {
            try tlvBuilder.append(.fileTypeName, value: fileName)
        }
        
        if let walletIndex = self.walletIndex {
            try tlvBuilder.append(.walletIndex, value: walletIndex)
        }
        
        guard let card = environment.card else {
            throw TangemSdkError.missingPreflightRead
        }
        
        if shouldReadPrivateFiles {
            try tlvBuilder.append(.pin, value: environment.accessCode.value)
                .append(.pin2, value: environment.passcode.value)
        } else {
            if card.firmwareVersion.doubleValue < 4 {
                try tlvBuilder.append(.pin, value: environment.accessCode.value)
            }
        }
        
        return CommandApdu(.readFileData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> ReadFileResponse {
        guard let tlv = apdu.getTlvData() else {
            throw TangemSdkError.deserializeApduFailed
        }
        let decoder = TlvDecoder(tlv: tlv)
        
        return ReadFileResponse(cardId: try decoder.decode(.cardId),
                                size: try decoder.decode(.size),
                                offset: try decoder.decode(.offset),
                                fileData: try decoder.decode(.issuerData) ?? Data(),
                                fileIndex: try decoder.decode(.fileIndex) ?? 0,
                                settings: try FileSettings(try decoder.decode(.fileSettings)),
                                ownerIndex: try decoder.decode(.fileOwnerIndex),
                                ownerPublicKey: try decoder.decode(.issuerPublicKey),
                                walletIndex: try decoder.decode(.walletIndex))
    }
}
