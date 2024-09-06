//
//  PreflightReadFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 30.10.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

/// Use this filter to filter out cards on preflight read stage. If preflight mode is set to `readCardOnly` or `fullCardRead`. `HandleErrors` flag must be switched on.
public protocol PreflightReadFilter {
    /// This method calls right after public information is read. User code is not required.  If preflight mode is set to `readCardOnly` or `fullCardRead`
    /// - Parameter card: The card that was read
    /// - Parameter environment: Current environment
    /// - Throws: Throw an error  with a localized message to the user, if the card should not be worked with.
    func onCardRead(_ card: Card, environment: SessionEnvironment) throws

    /// This method calls right after full card information is read. User code is required.  If preflight mode is set to `fullCardRead`
    /// - Parameter card: The card that was read
    /// - Parameter environment: Current environment
    /// - Throws: Throw an error  with a localized message to the user, if the card should not be worked with.
    func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws
}
