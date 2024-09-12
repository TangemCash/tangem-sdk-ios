//
//  OptionSetCustomStringConvertible.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.06.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol OptionSetCustomStringConvertible: CustomStringConvertible {}

extension OptionSetCustomStringConvertible where Self: OptionSetCodable {
    var description: String {
        if let data = try? JSONEncoder().encode(self),
           let string = String(data: data, encoding: .utf8) {
            return string.replacingOccurrences(of: "{[", with: "")
                .replacingOccurrences(of: "]}", with: "")
        }
        
        return ""
    }
}
