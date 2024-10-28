//
//  BLSUtils.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 25.05.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Bls_Signature

public struct BLSUtils {
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Implementation
    
    /// hkdf_mod_r() implementaion (KeyGen)
    /// https://eips.ethereum.org/EIPS/eip-2333#hkdf_mod_r-1
    /// https://www.ietf.org/archive/id/draft-irtf-cfrg-bls-signature-05.html#name-keygen
    /// - Parameters:
    ///   - inputKeyMaterial: input keying material
    ///   - salt: salt value
    ///   - keyInfo: optional context and application specific information (can be a zero-length octet string)
    /// - Returns: Generated key
    func generateKey(inputKeyMaterial: Data, salt: Data = Constants.salt, keyInfo: Data? = nil) throws -> Data {
        let inputKeyMaterialData = inputKeyMaterial + Data([0x00])
        let prk = HKDFUtil<SHA256>.extract(inputKeyMaterial: inputKeyMaterialData, salt: salt)

        let info = keyInfo ?? Data() + Constants.okmCount.bytes2
        let okm = HKDFUtil<SHA256>.expand(pseudoRandomKey: prk, info: info, outputByteCount: Constants.okmCount)

        guard let intKey = BigInt(okm.hexString, radix: 16) else {
            throw BLSError.keyGenerationFailed
        }

        let sk  = intKey % Constants.curveOrder
        
        if sk != 0 {
            return Data(hexString: sk.hexString)
        }

        let salt = salt.getSha256()
        
        return try generateKey(inputKeyMaterial: inputKeyMaterial, salt: salt, keyInfo: keyInfo)
    }
}

extension BLSUtils {
    enum Constants {
        /// Version of  keygen algorithm prior to number 4
        static let saltPreV4: Data = "BLS-SIG-KEYGEN-SALT-".data(using: .utf8)!

        /// Actual version of  keygen algorithm
        static let salt: Data = saltPreV4.getSha256()
        
        /// L, Calculated as ceil((3 * ceil(log2(r))) / 16). where r is s the order of the BLS 12-381
        fileprivate static let okmCount: Int = 48

        /// r, defined in  https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-bls-signature-04
        fileprivate static let curveOrder: BigInt = .init("52435875175126190479447740508185965837690552500527637822603658699938581184513", radix: 10)!
    }

    enum BLSError: Error {
        case keyGenerationFailed
    }
}

// MARK: - Bls_Signature Implementation

public extension BLSUtils {
    /// Obtain G2 point for bls curve
    /// - Parameters:
    ///   - publicKey: Public key hash
    ///   - message: Message hash
    /// - Returns: Hash of G2Element point
    func augSchemeMplG2Map(publicKey: String, message: String) throws -> String {
        try BlsSignatureSwift.augSchemeMplG2Map(publicKey: publicKey, message: message)
    }

    /// Perform Aggregate hash signatures
    /// - Parameter signatures: Signatures hash's
    /// - Returns: Hash of result aggreate signature at bls-signature library
    func aggregate(signatures: [String]) throws -> String {
        try BlsSignatureSwift.aggregate(signatures: signatures)
    }

    /// Obtain public key from private key
    /// - Parameter privateKey: Private key hash string
    /// - Returns: Public key hash
    func makePublicKey(from privateKey: String) throws -> String {
        try BlsSignatureSwift.publicKey(from: privateKey)
    }

    /// Verify message payload for signatures
    /// - Parameters:
    ///   - signatures: Hash signatures
    ///   - publicKey: Hash public key
    ///   - message: Has payload message
    /// - Returns: Bool result of valid or no
    func verify(signatures: [String], with publicKey: String, message: String) throws -> Bool {
        try BlsSignatureSwift.verify(signatures: signatures, with: publicKey, message: message)
    }
}
