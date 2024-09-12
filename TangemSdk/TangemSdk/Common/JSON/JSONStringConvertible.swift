//
//  JSONStringConvertible.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// The basic protocol for command response
public protocol JSONStringConvertible: Encodable {
    var json: String {get}
}

public extension JSONStringConvertible {
    var json: String {
        let data = (try? JSONEncoder.tangemSdkEncoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }

    var testJson: String {
        let data = (try? JSONEncoder.tangemSdkTestEncoder.encode(self)) ?? Data()
        return String(data: data, encoding: .utf8)!
    }

    func eraseToAnyResponse() -> AnyJSONRPCResponse {
        AnyJSONRPCResponse(self)
    }
}
