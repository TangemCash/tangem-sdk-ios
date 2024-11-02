//
//  SignCommand.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 03/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Response for `SignCommand`.
public struct SignResponse: JSONStringConvertible {
    /// CID, Unique Tangem card ID number
    public let cardId: String
    /// Signed hashes (array of resulting signatures)
    public let signatures: [Data]
    /// Total number of signed  hashes returned by the wallet since its creation. COS: 1.16+
    public let totalSignedHashes: Int?
}

/// Signs transaction hashes using a wallet private key, stored on the card.
class SignCommand: Command {
    typealias Response = SignResponse
    typealias CommandResponse = PartialSignResponse

    var requiresPasscode: Bool { return true }
    
    private let walletPublicKey: Data
    private let derivationPath: DerivationPath?

    private var chunkHashesHelper: ChunkedHashesContainer

    /// Command initializer
    /// - Parameters:
    ///   - hashes: Array of transaction hashes.
    ///   - walletPublicKey: Public key of the wallet, using for sign.
    ///   - derivationPath: Derivation path of the wallet. Optional. COS v. 4.28 and higher,
    init(hashes: [Data], walletPublicKey: Data, derivationPath: DerivationPath? = nil) {
        self.walletPublicKey = walletPublicKey
        self.derivationPath = derivationPath
        self.chunkHashesHelper = ChunkedHashesContainer(hashes: hashes)
    }
    
    deinit {
        Log.debug("SignCommand deinit")
    }
    
    func performPreCheck(_ card: Card) -> TangemSdkError? {
        guard let wallet = card.wallets[walletPublicKey] else {
            return .walletNotFound
        }
        
        if derivationPath != nil {
            if card.firmwareVersion < .hdWalletAvailable {
                return .notSupportedFirmwareVersion
            }
            
            guard wallet.curve.supportsDerivation else {
                return .unsupportedCurve
            }
            
            if !card.settings.isHDWalletAllowed {
                return .hdWalletDisabled
            }
        }
        
        //Before v4
        if let remainingSignatures = wallet.remainingSignatures,
           remainingSignatures == 0 {
            return .noRemainingSignatures
        }
        
        if let defaultSigningMethods = card.settings.defaultSigningMethods {
            if !defaultSigningMethods.contains(.signHash) {
                return .signHashesNotAvailable
            }
        }
        
        if card.firmwareVersion.doubleValue < 2.28, card.settings.securityDelay > 15000 {
            return .oldCard
        }
        
        return nil
    }
    
    func run(in session: CardSession, completion: @escaping CompletionResult<SignResponse>) {
        if chunkHashesHelper.isEmpty {
            completion(.failure(.emptyHashes))
            return
        }
        
        sign(in: session, completion: completion)
    }
    
    func mapError(_ card: Card?, _ error: TangemSdkError) -> TangemSdkError {        
        if case .unknownStatus = error {
            return .nfcStuck
        }
        
        return error
    }
    
    func sign(in session: CardSession, completion: @escaping CompletionResult<SignResponse>) {
        if chunkHashesHelper.chunksCount > 1 {
            session.viewDelegate.showAlertMessage("sign_multiple_chunks_part".localized([chunkHashesHelper.currentChunkIndex + 1, chunkHashesHelper.chunksCount]))
        }
        
        transceive(in: session) { result in
            switch result {
            case .success(let response):
                self.chunkHashesHelper.addSignedChunk(response.signedChunk)

                if self.chunkHashesHelper.currentChunkIndex >= self.chunkHashesHelper.chunksCount {
                    session.environment.card?.wallets[self.walletPublicKey]?.totalSignedHashes = response.totalSignedHashes

                    do {
                        let signatures = try self.processSignatures(with: session.environment)

                        if let remainingSignatures = session.environment.card?.wallets[self.walletPublicKey]?.remainingSignatures {
                            session.environment.card?.wallets[self.walletPublicKey]?.remainingSignatures = remainingSignatures - signatures.count
                        }

                        completion(.success(SignResponse(cardId: response.cardId,
                                                         signatures: signatures,
                                                         totalSignedHashes: response.totalSignedHashes)))
                    } catch {
                        completion(.failure(error.toTangemSdkError()))
                    }
                    
                    return
                }

                if let firmwareVersion = session.environment.card?.firmwareVersion,
                   firmwareVersion < .keysImportAvailable {
                    session.restartPolling(silent: true)
                }

                self.sign(in: session, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func serialize(with environment: SessionEnvironment) throws -> CommandApdu {
        guard let walletIndex = environment.card?.wallets[walletPublicKey]?.index else {
            throw TangemSdkError.walletNotFound
        }

        let chunk = try chunkHashesHelper.getCurrentChunk()
        
        let hashSize = chunk.hashSize
        let hashSizeData = hashSize > 255 ? hashSize.bytes2 : hashSize.byte

        let flattenHashes = Data(chunk.hashes.flatMap { $0.data })
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.accessCode.value)
            .append(.pin2, value: environment.passcode.value)
            .append(.cardId, value: environment.card?.cardId)
            .append(.transactionOutHashSize, value: hashSizeData)
            .append(.transactionOutHash, value: flattenHashes)
            //Wallet index works only on COS v.4.0 and higher. For previous version index will be ignored
            .append(.walletIndex, value: walletIndex)
        
        if let cvc = environment.cvc {
            try tlvBuilder.append(.cvc, value: cvc)
        }
        
        /**
         * Application can optionally submit a public key Terminal_PublicKey in [SignCommand].
         * Submitted key is stored by the Tangem card if it differs from a previous submitted Terminal_PublicKey.
         * The Tangem card will not enforce security delay if [SignCommand] will be called with
         * TerminalTransactionSignature parameter containing a correct signature of raw data to be signed made with TerminalPrivateKey
         * (this key should be generated and securily stored by the application).
         * COS version 2.30 and later.
         */
        if let terminalKeys = self.retrieveTerminalKeys(from: environment) {
            let signedData = try flattenHashes.sign(privateKey: terminalKeys.privateKey)
            
            try tlvBuilder
                .append(.terminalTransactionSignature, value: signedData)
                .append(.terminalPublicKey, value: terminalKeys.publicKey)
        }
        
        if let derivationPath = self.derivationPath {
            try tlvBuilder.append(.walletHDPath, value: derivationPath)
        }
        
        return CommandApdu(.sign, tlv: tlvBuilder.serialize())
    }
    
    func deserialize(with environment: SessionEnvironment, from apdu: ResponseApdu) throws -> PartialSignResponse {
        guard let tlv = apdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TangemSdkError.deserializeApduFailed
        }
        
        let decoder = TlvDecoder(tlv: tlv)
        let chunk = try chunkHashesHelper.getCurrentChunk()

        let signatureBLOB: Data = try decoder.decode(.walletSignature)
        let signatures = splitSignatureBLOB(signatureBLOB, numberOfSignatures: chunk.hashes.count)

        let signedHashes = zip(chunk.hashes, signatures).map { (hash, signature) in
            SignedHash(
                index: hash.index,
                data: hash.data,
                signature: signature
            )
        }

        let signedChunk = SignedChunk(signedHashes: signedHashes)

        let response = PartialSignResponse(
            cardId: try decoder.decode(.cardId),
            signedChunk: signedChunk,
            totalSignedHashes: try decoder.decode(.walletSignedHashes)
        )

        return response
    }
    
    private func processSignatures(with environment: SessionEnvironment) throws -> [Data] {
        let signatures = chunkHashesHelper.getSignatures()

        if environment.card?.wallets[self.walletPublicKey]?.curve == .secp256k1,
           environment.config.canonizeSecp256k1Signatures {
            let secp256k1 = Secp256k1Utils()
            let normalizedSignatures = try signatures.map { try secp256k1.normalizeSignature($0) }
            if normalizedSignatures.count != signatures.count {
                throw TangemSdkError.cryptoUtilsError("Normalization error")
            }
            
            return normalizedSignatures
        }
        
        return signatures
    }
    
    private func splitSignatureBLOB(_ signature: Data, numberOfSignatures: Int) -> [Data] {
        var signatures = [Data]()
        let signatureSize = signature.count / numberOfSignatures
        for index in 0..<numberOfSignatures {
            let offsetMin = index * signatureSize
            let offsetMax = offsetMin + signatureSize
            
            let sig = signature[offsetMin..<offsetMax]
            signatures.append(sig)
        }
        
        return signatures
    }
    
    private func retrieveTerminalKeys(from environment: SessionEnvironment) -> KeyPair? {
        guard let card = environment.card,
              card.settings.isLinkedTerminalEnabled,
              card.firmwareVersion < .hdWalletAvailable else {
                  return nil
              }
        
        return environment.terminalKeys
    }
}

// MARK: - PartialSignResponse

struct PartialSignResponse {
    /// CID, Unique Tangem card ID number
    let cardId: String
    /// Signed hashes (array of resulting signatures)
    let signedChunk: SignedChunk
    /// Total number of signed  hashes returned by the wallet since its creation. COS: 1.16+
    let totalSignedHashes: Int?
}


