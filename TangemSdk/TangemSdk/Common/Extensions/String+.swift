//
//  String+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public extension String {
    func sha256() -> Data {
        let data = Data(Array(utf8))
        return data.getSha256()
    }

    func sha512() -> Data {
        let data = Data(Array(utf8))
        return data.getSha512()
    }
    
    internal var titleFormatted: String {
        let separator = Array(repeating: "-", count: 16).joined()
        return "\(separator) \(self) \(separator)"
    }
    
    func remove(_ substring: String) -> String {
        return self.replacingOccurrences(of: substring, with: "")
    }
    
    internal func capitalizingFirst() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    internal func lowercasingFirst() -> String {
        return prefix(1).lowercased() + dropFirst()
    }

    internal var localized: String {
        Localization.getFormat(for: self)
    }

    internal func localized(_ arguments: [CVarArg]) -> String {
        let format = Localization.getFormat(for: self)
        return String(format: format, arguments: arguments)
    }

    internal func localized(_ arguments: CVarArg) -> String {
        let format = Localization.getFormat(for: self)
        return String(format: format, arguments)
    }
    
    internal func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }

    internal func leadingZeroPadding(toLength newLength: Int) -> String {
        guard count < newLength else { return self }
            
        let prefix = String(repeating: "0", count: newLength - count)
        return prefix + self
    }
}

extension DefaultStringInterpolation {
    mutating func appendInterpolation(_ data: Data) {
        appendLiteral(data.hexString)
    }
    
    mutating func appendInterpolation(_ byte: Byte) {
        appendLiteral(byte.hexString)
    }
}

extension String.SubSequence {
    internal func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
