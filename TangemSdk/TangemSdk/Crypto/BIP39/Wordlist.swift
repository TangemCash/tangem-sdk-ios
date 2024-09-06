//
//  Wordlist.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 01.03.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

extension BIP39 {
    public enum Wordlist: CaseIterable {
        case en
    }
}

extension BIP39.Wordlist {
    /// This var reads a big array from a file
    public var words: [String] {
        (try? readWords(from: fileName)) ?? []
    }

    private var fileName: String {
        switch self {
        case .en:
            return "english"
        }
    }

    private func readWords(from fileName: String) throws -> [String] {
        guard let path = Bundle.sdkBundle.path(forResource: fileName, ofType: "txt") else {
            throw MnemonicError.invalidWordsFile
        }

        let content = try String(contentsOfFile: path, encoding: .utf8)
        let words = content.trim().components(separatedBy: "\n")

        guard words.count == 2048 else {
            throw MnemonicError.invalidWordCount
        }

        return words
    }
}
