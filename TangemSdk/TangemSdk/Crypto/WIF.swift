//
//  WIF.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 10.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum WIF {
    public static func encodeToWIFCompressed(_ privateKey: Data, networkType: NetworkType) -> String {
        let extended = networkType.prefix + privateKey + Constants.compressedSuffix
        return extended.base58CheckEncodedString
    }

    public static func decodeWIFCompressed(_ string: String) -> Data? {
        guard let decoded = string.base58CheckDecodedData else { return nil }

        var data = decoded.dropFirst()

        if !string.starts(with: Constants.uncompressedMainnetPrefix)
            && !string.starts(with: Constants.uncompressedTestnetPrefix),
           let lastByte = data.last, Data(lastByte) == Constants.compressedSuffix {
            data = data.dropLast() // remove compressedSuffix
        }

        return data
    }
}

fileprivate extension WIF {
    enum Constants {
        static let prefixMainnet = Data(hexString: "0x80")
        static let prefixTestnet = Data(hexString: "0xEF")
        static let compressedSuffix = Data(hexString: "0x01")
        static let uncompressedMainnetPrefix = "5"
        static let uncompressedTestnetPrefix = "9"
    }
}

fileprivate extension NetworkType {
    var prefix: Data {
        switch self {
        case .mainnet:
            return WIF.Constants.prefixMainnet
        case .testnet:
            return WIF.Constants.prefixTestnet
        }
    }
}
