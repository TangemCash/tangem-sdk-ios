//
//  CardReader.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26/09/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public enum NFCTagType: Equatable, CustomStringConvertible {
    case tag(uid: Data)
    case unknown
    case none
    
    public var description: String {
        switch self {
        case .tag(let uid):
            return "iso7816 Tag with uid: \(uid.hexString)"
        case .unknown:
            return "Unknown NFC Tag type"
        case .none:
            return "Tag not connected"
        }
    }
}

/// Allows interaction between the phone or any other terminal and Tangem card.
/// Its default implementation, `NfcReader`, is in our module.
public protocol CardReader: AnyObject {
    /// For setting alertMessage into NFC popup
    var isPaused: Bool { get }
    var isReady: Bool { get }
    var alertMessage: String { get set }
    var tag: CurrentValueSubject<NFCTagType,TangemSdkError> { get }
    var viewEventsPublisher: CurrentValueSubject<CardReaderViewEvent, Never> { get }
    func startSession(with message: String)
    func resumeSession()
    func stopSession(with errorMessage: String?)
    func pauseSession(with errorMessage: String?)
    func stopSession(with error: Error)
    func sendPublisher(apdu: CommandApdu) -> AnyPublisher<ResponseApdu, TangemSdkError>
    func restartPolling(silent: Bool)
}

public extension CardReader {
    func pauseSession(with errorMessage: String? = nil) {
        pauseSession(with: errorMessage)
    }
    
    func stopSession(with errorMessage: String? = nil) {
        stopSession(with: errorMessage)
    }
}

public enum CardReaderViewEvent: Equatable {
    case none
    case sessionStarted
    case sessionStopped
    case tagConnected
    case tagLost
}
