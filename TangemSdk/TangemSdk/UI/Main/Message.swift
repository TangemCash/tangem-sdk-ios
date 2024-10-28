//
//  Message.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Wrapper for a message that can be shown to user after a start of NFC session.
public struct Message: Codable {
    let header: String?
    let body: String?
    
    var alertMessage: String? {
        if header == nil && body == nil {
            return nil
        }
        
        var alertMessage = ""
        
        if let header = header {
            alertMessage = "\(header)\n"
        }
        
        if let body = body {
            alertMessage += body
        }
        
        return alertMessage
    }
    
    public init(header: String?, body: String? = nil) {
        self.header = header
        self.body = body
    }
    
    public init?(_ jsonString: String) {
        guard let jsonData = jsonString.data(using: .utf8),
              let decoded = try? JSONDecoder.tangemSdkDecoder.decode(Message.self, from: jsonData) else {
            return nil
        }

        self.header = decoded.header
        self.body = decoded.body
    }
}
