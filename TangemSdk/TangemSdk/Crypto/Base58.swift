//
//  Base58.swift
//  TangemSdk
//
//  Created by Alex Vlasov.
//  Copyright © 2018 Alex Vlasov. All rights reserved.

import Foundation

fileprivate enum Base58 {
    private static let base58Alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

    // Encode
    static func base58FromBytes(_ bytes: [UInt8]) -> String {
        var bytes = bytes
        var zerosCount = 0
        var length = 0

        for b in bytes {
            if b != 0 { break }
            zerosCount += 1
        }

        bytes.removeFirst(zerosCount)

        let size = bytes.count * 138 / 100 + 1

        var base58: [UInt8] = Array(repeating: 0, count: size)
        for b in bytes {
            var carry = Int(b)
            var i = 0

            for j in 0...base58.count-1 where carry != 0 || i < length {
                carry += 256 * Int(base58[base58.count - j - 1])
                base58[base58.count - j - 1] = UInt8(carry % 58)
                carry /= 58
                i += 1
            }

            assert(carry == 0)

            length = i
        }

        // skip leading zeros
        var zerosToRemove = 0
        var str = ""
        for b in base58 {
            if b != 0 { break }
            zerosToRemove += 1
        }
        base58.removeFirst(zerosToRemove)

        while 0 < zerosCount {
            str = "\(str)1"
            zerosCount -= 1
        }

        for b in base58 {
            str = "\(str)\(base58Alphabet[String.Index(utf16Offset: Int(b), in: base58Alphabet)])"
        }

        return str
    }

    // Decode
    static func bytesFromBase58(_ base58: String) -> [UInt8] {
        // remove leading and trailing whitespaces
        let string = base58.trimmingCharacters(in: CharacterSet.whitespaces)
        guard !string.isEmpty else { return [] }

        // count leading ASCII "1"'s [decodes directly to binary zero bytes]
        var leadingZeros = 0
        for c in string {
            if c != "1" { break }
            leadingZeros += 1
        }

        // calculate the size of the decoded output, rounded up
        let size = (string.lengthOfBytes(using: String.Encoding.utf8) - leadingZeros) * 733 / 1000 + 1

        // allocate a buffer large enough for the decoded output
        var base58: [UInt8] = Array(repeating: 0, count: size + leadingZeros)

        // decode what remains of the data
        var length = 0
        for c in string where c != " " {
            // search for base58 character
            guard let base58Index = base58Alphabet.firstIndex(of: c) else { return [] }

            var carry = base58Index.utf16Offset(in: base58Alphabet)
            var i = 0
            for j in 0...base58.count where carry != 0 || i < length {
                carry += 58 * Int(base58[base58.count - j - 1])
                base58[base58.count - j - 1] = UInt8(carry % 256)
                carry /= 256
                i += 1
            }

            assert(carry == 0)
            length = i
        }

        // calculate how many leading zero bytes we have
        var totalZeros = 0
        for b in base58 {
            if b != 0 { break }
            totalZeros += 1
        }
        // remove the excess zero bytes
        base58.removeFirst(totalZeros - leadingZeros)

        return base58
    }
}

// MARK: - Data+

public extension Data {
    var base58EncodedString: String {
        let bytes = Array(self)
        return bytes.base58EncodedString
    }

    var base58CheckEncodedString: String {
        let bytes = Array(self)
        return bytes.base58CheckEncodedString
    }
}

// MARK: - Array+

public extension Array where Element == UInt8 {
    var base58EncodedString: String {
        guard !self.isEmpty else { return "" }

        return Base58.base58FromBytes(self)
    }

    var base58CheckEncodedString: String {
        guard !self.isEmpty else { return "" }

        let checksum = self.getDoubleSha256().prefix(4)
        let bytes = self + checksum
        return Base58.base58FromBytes(bytes)
    }
}

// MARK: - String+

public extension String {
    var base58DecodedData: Data {
        Data(base58DecodedBytes)
    }

    var base58DecodedBytes: [UInt8] {
        return Base58.bytesFromBase58(self)
    }

    var base58CheckDecodedData: Data? {
        guard let bytes = base58CheckDecodedBytes else { return nil }

        return Data(bytes)
    }

    var base58CheckDecodedBytes: [UInt8]? {
        let bytes = Base58.bytesFromBase58(self)

        guard bytes.count >= 4 else { return nil }

        let checksum = Array(bytes.suffix(4))
        let bytesWithoutCheck = Array(bytes.dropLast(4))
        let calculatedChecksum = Array(bytesWithoutCheck.getDoubleSha256().prefix(4))

        if checksum != calculatedChecksum { return nil }

        return bytesWithoutCheck
    }
}
