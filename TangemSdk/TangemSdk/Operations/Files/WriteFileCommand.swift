//
//  WriteFileCommand.swift
//  TangemSdk
//
//  Created by Andrew Son on 10/7/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Deserialized response for `WriteFileCommand`
public struct WriteFileResponse: JSONStringConvertible {
    let cardId: String
    let fileIndex: Int?
}

/// Command for writing file on card
public final class WriteFileCommand: Command {
    var requiresPasscode: Bool { isWritingByUserCodes }
    
    private let data: Data
    private let startingSignature: Data?
    private let finalizingSignature: Data?
    private let counter: Int?
    private let walletPublicKey: Data?
    private let fileVisibility: FileVisibility?
    private let isWritingByUserCodes: Bool
    
    private var walletIndex: Int? = nil
    private var mode: FileDataMode = .initiateWritingFile
    private var offset: Int = 0
    private var fileIndex: Int = 0
    
    private static let singleWriteSize = 900
    private static let maxSize = 48 * 1024
    
    /// Initializer for writing the file by the file owner
    /// - Parameters:
    ///   - data: Data to write
    ///   - startingSignature: Starting signature of the file data. You can use `FileHashHelper` to generate signatures or use it as a reference to create the signature yourself
    ///   - finalizingSignature: Finalizing signature of the file data. You can use `FileHashHelper` to generate signatures or use it as a reference to create the signature yourself
    ///   - counter: File counter to prevent replay attack
    ///   - fileVisibility: Optional visibility setting for the file. COS 4.0+
    ///   - walletPublicKey: Optional link to the card's wallet. COS 4.0+
    public init(data: Data, startingSignature: Data, finalizingSignature: Data, counter: Int,
         fileVisibility: FileVisibility? = nil, walletPublicKey: Data? = nil) {
        self.data = data
        self.startingSignature = startingSignature
        self.finalizingSignature = finalizingSignature
        self.counter = counter
        self.walletPublicKey = walletPublicKey
        self.fileVisibility = fileVisibility
        self.isWritingByUserCodes = false
    }
    
    /// Initializer for writing the file by the user
    /// - Parameters:
    ///   - data: Data to write
    ///   - fileVisibility: Optional visibility setting for the file. COS 4.0+
    ///   - walletPublicKey: Optional link to the card's wallet. COS 4.0+
    public init(data: Data, fileVisibility: FileVisibility? = nil, walletPublicKey: Data? = nil) {
        self.data = data
        self.walletPublicKey = walletPublicKey
        self.fileVisibility = fileVisibility
        self.isWritingByUserCodes = true
        
        self.startingSignature = nil
        self.finalizingSignature = nil
        self.counter = nil
    }
    
    /// Convenience initializer
    /// - Parameter file: File to write
    public convenience init(_ file: FileToWrite) {
        switch file {
        case .byUser(_, _, let fileVisibility, let walletPublicKey):
            self.init(data: file.payload, fileVisibility: fileVisibility, walletPublicKey: walletPublicKey)
        case .byFileOwner(_, let startingSignature, let finalizingSignature,
                          let counter, _, let fileVisibility, let walletPublicKey):
            self.init(data: file.payload, startingSignature: startingSignature, finalizingSignature: finalizingSignature,
                      counter: counter, fileVisibility: fileVisibility, walletPublicKey: walletPublicKey)
        }
    }
    
    public func run(in session: CardSession, completion: @escaping CompletionResult<WriteFileResponse>) {
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
        
        writeFileData(session: session, completion: completion)
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        if card.firmwareVersion < .filesAvailable {
            return .notSupportedFirmwareVersion
        }
        
        if !card.settings.isFilesAllowed {
            return .filesDisabled
        }
        
        if isWritingByUserCodes, card.firmwareVersion.doubleValue < 3.34 {
            return .notSupportedFirmwareVersion
        }
        
        if fileVisibility != nil && card.firmwareVersion.doubleValue < 4 {
            return .fileSettingsUnsupported
        }
        
        if walletPublicKey != nil && card.firmwareVersion.doubleValue < 4 {
            return .fileSettingsUnsupported
        }
        
        if data.count > WriteFileCommand.maxSize {
            return .dataSizeTooLarge
        }
        
        if !verifySignatures(publicKey: card.issuer.publicKey, cardId: card.cardId) {
            return .verificationFailed
        }
        
        return nil
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {
        guard let card = card else { return error }
        
        if case .invalidParams = error, isCounterRequired(card: card) {
            return .dataCannotBeWritten
        }
        
        if case .invalidState = error, card.settings.isIssuerDataProtectedAgainstReplay {
            return .overwritingDataIsProhibited
        }
        
        return error
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.cardId, value: environment.card?.cardId)
            .append(.pin, value: environment.accessCode.value)
            .append(.interactionMode, value: mode)
        
        switch mode {
        case .initiateWritingFile:
            try tlvBuilder.append(.size, value: data.count)
            
            if let startingSignature = self.startingSignature, let counter = self.counter {
                try tlvBuilder.append(.issuerDataSignature, value: startingSignature)
                    .append(.issuerDataCounter, value: counter)
            } else {
                try tlvBuilder.append(.pin2, value: environment.passcode.value)
            }
            
            if let walletIndex = self.walletIndex {
                try tlvBuilder.append(.walletIndex, value: walletIndex)
            }
            
            if let fileVisibility = self.fileVisibility {
                guard let card = environment.card else {
                   throw TangemSdkError.missingPreflightRead
                }
                
                try tlvBuilder.append(.fileSettings, value: fileVisibility.serializeValue(for: card.firmwareVersion))
            }
            
        case .writeFile:
            let partSize = min(WriteFileCommand.singleWriteSize, data.count - offset)
            let dataChunk = data[offset..<offset+partSize]
            
            try tlvBuilder.append(.issuerData, value: dataChunk)
                .append(.offset, value: offset)
                .append(.fileIndex, value: fileIndex)
            
        case .confirmWritingFile:
            try tlvBuilder.append(.fileIndex, value: fileIndex)
            
            if let finalizingSignature = self.finalizingSignature {
                try tlvBuilder.append(.issuerDataSignature, value: finalizingSignature)
            } else {
                try tlvBuilder.append(.codeHash, value: data.getSha256())
                    .append(.pin2, value: environment.passcode.value)
            }
        default:
            break
        }
        
        return CommandApdu(.writeFileData, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> WriteFileResponse {
        guard let tlv = apdu.getTlvData() else {
            throw TangemSdkError.deserializeApduFailed
        }
        let decoder = TlvDecoder(tlv: tlv)
        return WriteFileResponse(cardId: try decoder.decode(.cardId),
                                 fileIndex: try decoder.decode(.fileIndex))
    }
    
    // MARK: Private functions
    
    private func writeFileData(session: CardSession, completion: @escaping CompletionResult<WriteFileResponse>) {
        // TODO: Insert view delegate method to display progress to user
        transceive(in: session) { (result) in
            switch result {
            case .success(let response):
                switch self.mode {
                case .initiateWritingFile:
                    self.fileIndex = response.fileIndex ?? 0
                    self.mode = .writeFile
                    self.writeFileData(session: session, completion: completion)
                case .writeFile:
                    self.offset += WriteFileCommand.singleWriteSize
                    if self.offset >= self.data.count {
                        self.mode = .confirmWritingFile
                    }
                    self.writeFileData(session: session, completion: completion)
                case .confirmWritingFile:
                    completion(.success(WriteFileResponse(cardId: response.cardId, fileIndex: self.fileIndex)))
                default:
                    completion(.failure(.wrongInteractionMode))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func isCounterRequired(card: Card) -> Bool {
        if isWritingByUserCodes {
            return false
        }
        return card.settings.isIssuerDataProtectedAgainstReplay
    }
    
    private func verifySignatures(publicKey: Data, cardId: String) -> Bool {
        if isWritingByUserCodes { return true }
        
        guard let counter = self.counter,
              let startingSignature = self.startingSignature,
              let finalizingSignature = self.finalizingSignature else {
            return false
        }
        
        let startingSignatureIsValid = IssuerDataVerifier.verify(cardId: cardId,
                                                                 issuerDataSize: data.count,
                                                                 issuerDataCounter: counter,
                                                                 publicKey: publicKey,
                                                                 signature: startingSignature)
        let finalizingSignatureIsValid = IssuerDataVerifier.verify(cardId: cardId,
                                                                   issuerData: data,
                                                                   issuerDataCounter: counter,
                                                                   publicKey: publicKey,
                                                                   signature: finalizingSignature)
        
        return startingSignatureIsValid && finalizingSignatureIsValid
    }
    
}
