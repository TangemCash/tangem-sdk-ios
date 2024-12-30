//
//  ConsoleLogger.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

public class ConsoleLogger: TangemSdkLogger {
    private let loggerSerialQueue = DispatchQueue(label: "com.tangem.tangemsdk.consolelogger.queue")
    
    public init() {}
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss:SSS"
        return formatter
    }()
    
    public func log(_ message: String, level: Log.Level) {
    #if DEBUG
        guard Log.filter(level) else { return }
        
        loggerSerialQueue.async {
            print("\(level.emoji) \(self.dateFormatter.string(from: Date())):\(level.prefix) \(message)")
        }
    #endif //DEBUG
    }
}
