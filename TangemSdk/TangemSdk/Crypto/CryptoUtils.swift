//
//  CryptoUtils.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CommonCrypto
import CryptoKit

public enum CryptoUtils {
    
    /**
     * Generates array of random bytes.
     * It is used, among other things, to generate helper private keys
     * (not the one for the blockchains, that one is generated on the card and does not leave the card).
     *
     * - Parameter count: length of the array that is to be generated.
     */
    public static func generateRandomBytes(count: Int) throws -> Data  {
        var bytes = [Byte](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status == errSecSuccess {
            return Data(bytes)
        } else {
            throw TangemSdkError.failedToGenerateRandomSequence
        }
    }
    
    /**
     * Helper function to verify that the data was signed with a private key that corresponds
     * to the provided public key.
     *  - Parameter curve: Elliptic curve used
     *  - Parameter publicKey: Corresponding to the private key that was used to sing a message
     *  - Parameter message: The data that was signed
     *  - Parameter signature: Signed data
     */
    public static func verify(curve: EllipticCurve, publicKey: Data, message: Data, signature: Data) throws -> Bool {
        switch curve {
        case .secp256k1:
            let signature = try Secp256k1Signature(with: signature)
            return try signature.verify(with: publicKey, message: message)
        case .bip0340:
            let signature = try SchnorrSignature(with: signature)
            return try signature.verify(with: publicKey, message: message)
        case .ed25519, .ed25519_slip0010:
            let hash = message.getSha512()
            let pubKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
            return pubKey.isValidSignature(signature, for: hash)
        case .secp256r1:
            // TODO: Add support for compressed keys. CryptoKit works only on iOS16+.
            if publicKey.count == Constants.p256CompressedKeySize {
                throw TangemSdkError.unsupportedCurve
            }

            let pubKey = try P256.Signing.PublicKey(x963Representation: publicKey)
            let sig = try P256.Signing.ECDSASignature(rawRepresentation: signature)
            
            return pubKey.isValidSignature(sig, for: message)
        case .bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP:
            // TODO: implement
            throw TangemSdkError.unsupportedCurve
        }
    }

    public static func isPrivateKeyValid(_ privateKey: Data, curve: EllipticCurve) throws -> Bool {
        switch curve {
        case .secp256k1, .bip0340:
            return Secp256k1Utils().isPrivateKeyValid(privateKey)
        case .ed25519, .ed25519_slip0010:
            // Extended private keys not supported by CryptoKit
            if privateKey.count > Constants.ed25519PrivateKeySize {
                throw TangemSdkError.unsupportedCurve
            }

            let key = try? Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
            return key != nil
        case .secp256r1:
            let key = try? P256.Signing.PrivateKey(rawRepresentation: privateKey)
            return key != nil
        case .bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP:
            // TODO: implement
            throw TangemSdkError.unsupportedCurve
        }
    }

    // We can create only decompressed secp256r1 key here.
    public static func makePublicKey(from privateKey: Data, curve: EllipticCurve) throws -> Data {
        switch curve {
        case .secp256k1:
            return try Secp256k1Utils().createPublicKey(privateKey: privateKey, compressed: true)
        case .bip0340:
            return try Secp256k1Utils().createXOnlyPublicKey(privateKey: privateKey)
        case .ed25519, .ed25519_slip0010:
            // Extended private keys not supported by CryptoKit
            if privateKey.count > Constants.ed25519PrivateKeySize {
                throw TangemSdkError.unsupportedCurve
            }

            let key = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKey)
            return key.publicKey.rawRepresentation
        case .secp256r1:
            let key = try P256.Signing.PrivateKey(rawRepresentation: privateKey)
            return key.publicKey.rawRepresentation
        case .bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP:
            // TODO: implement
            throw TangemSdkError.unsupportedCurve
        }
    }
    
    /**
     * Helper function to verify that the data was signed with a private key that corresponds
     * to the provided public key.
     *  - Parameter curve: Elliptic curve used
     *  - Parameter publicKey: Corresponding to the private key that was used to sing a message
     *  - Parameter hash: The data  hash that was signed
     *  - Parameter signature: Signed data
     */
    public static func verify(curve: EllipticCurve, publicKey: Data, hash: Data, signature: Data) throws -> Bool {
        switch curve {
        case .secp256k1:
            let signature = try Secp256k1Signature(with: signature)
            return try signature.verify(with: publicKey, hash: hash)
        case .bip0340:
            let signature = try SchnorrSignature(with: signature)
            return try signature.verify(with: publicKey, hash: hash)
        case .ed25519, .ed25519_slip0010:
            let pubKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKey)
            return pubKey.isValidSignature(signature, for: hash)
        case .secp256r1:
            // TODO: Add support for compressed keys. CryptoKit works only on iOS16+.
            if publicKey.count == Constants.p256CompressedKeySize {
                throw TangemSdkError.unsupportedCurve
            }

            let pubKey = try P256.Signing.PublicKey(x963Representation: publicKey)
            let sig = try P256.Signing.ECDSASignature(rawRepresentation: signature)
            return pubKey.isValidSignature(sig, for: CustomSha256Digest(hash: hash))
        case .bls12381_G2, .bls12381_G2_AUG, .bls12381_G2_POP:
            // TODO: implement
            throw TangemSdkError.unsupportedCurve
        }
    }

    /// Verify secp256r1 signature
    @available(iOS 16.0, *)
    public static func verifySecp256r1Signature(publicKey: Data, hash: Data, signature: Data) throws -> Bool {
        if publicKey.count == Constants.p256CompressedKeySize {
            let pubKey = try P256.Signing.PublicKey(compressedRepresentation: publicKey)
            let sig = try P256.Signing.ECDSASignature(rawRepresentation: signature)
            return pubKey.isValidSignature(sig, for: CustomSha256Digest(hash: hash))
        }

        return try verify(curve: .secp256r1, publicKey: publicKey, hash: hash, signature: signature)
    }

    public static func crypt(operation: Int, algorithm: Int, options: Int, key: Data, dataIn: Data) throws -> Data {
        return try key.withUnsafeBytes { keyUnsafeRawBufferPointer in
            return try dataIn.withUnsafeBytes { dataInUnsafeRawBufferPointer in
                // Give the data out some breathing room for PKCS7's padding.
                let dataOutSize: Int = dataIn.count + kCCBlockSizeAES128*2
                let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutSize,
                                                               alignment: 1)
                defer { dataOut.deallocate() }
                var dataOutMoved: Int = 0
                let status = CCCrypt(CCOperation(operation), CCAlgorithm(algorithm),
                                     CCOptions(options),
                                     keyUnsafeRawBufferPointer.baseAddress, key.count,
                                     nil,
                                     dataInUnsafeRawBufferPointer.baseAddress, dataIn.count,
                                     dataOut, dataOutSize, &dataOutMoved)
                guard status == kCCSuccess else { throw status }
                return Data(bytes: dataOut, count: dataOutMoved)
            }
        }
    }
}

fileprivate struct CustomSha256Digest: Digest {
    static var byteCount: Int { 32 }
    
    let hash: Data
    
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
       try hash.withUnsafeBytes(body)
    }
}

// MARK: - Constants
private extension CryptoUtils {
    enum Constants {
        static let p256CompressedKeySize = 33
        static let ed25519PrivateKeySize = 32
    }
}
