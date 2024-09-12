//
//  CardIdFormatter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 18.12.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Formatting CID in more readable manner
public struct CardIdFormatter {
    public var style: CardIdDisplayFormat
    
    public init(style: CardIdDisplayFormat = .full) {
        self.style = style
    }
    
    public func string(from cardId: String) -> String? {
        switch style {
        case .none:
            return nil
        case .full:
            return split(cardId)
        case .last(let numbers):
            let cropped = String(cardId.suffix(numbers))
            let splitted = split(cropped)
            return format(splitted)
        case .lastMasked(let numbers, let mask):
            let cropped = String(cardId.suffix(numbers))
            let splitted = split(cropped)
            return "\(mask)\(splitted)"
        case .lastLunh(let numbers):
            let cropped = String(cardId.dropLast().suffix(numbers))
            let splitted = split(cropped)
            return format(splitted)
        }
    }
    
    private func format(_ string: String) -> String {
        return "cid_format".localized(string)
    }
    
    private func split(_ cardId: String) -> String {
        let chunks: [String] = stride(from: cardId.count, to: 0, by: -4).map {
            let endIndex = cardId.index(cardId.startIndex, offsetBy: $0)
            let offset = Swift.max($0 - 4, 0)
            let startIndex = cardId.index(cardId.startIndex, offsetBy: offset)
            return String(cardId[startIndex ..< endIndex])
        }
        
        let nbsp = " "
        return chunks.reversed().joined(separator: nbsp)
    }
}
