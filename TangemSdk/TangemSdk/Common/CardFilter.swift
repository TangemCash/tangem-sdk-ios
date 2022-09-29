//
//  CardFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 07.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
public struct CardFilter {
    /// Filter that can be used to limit cards that can be interacted with in TangemSdk.
    public var allowedCardTypes: [FirmwareVersion.FirmwareType] = [.release, .sdk]
    
    /// Use this filter to configure cards allowed to work with your app
    public var cardIdFilter: ItemFilter? = nil
    
    /// Use this filter to configure batches allowed to work with your app
    public var batchIdFilter: ItemFilter? = nil
    
    /// Use this filter to configure issuers allowed to work with your app
    public var issuerFilter: ItemFilter? = nil
    
    /// Custom error localized description
    public var localizedDescription: String? = nil
    
    public static var `default`: CardFilter = .init()
    
    private var wrongCardError: TangemSdkError {
        .wrongCardType(localizedDescription)
    }
    
    public func verifyCard(_ card: Card) throws {
        if !allowedCardTypes.contains(card.firmwareVersion.type) {
            throw wrongCardError
        }
        
        if let batchIdFilter = batchIdFilter,
           !batchIdFilter.isAllowed(card.batchId) {
            throw wrongCardError
        }
        
        if let issuerFilter = issuerFilter,
           !issuerFilter.isAllowed(card.issuer.name) {
            throw wrongCardError
        }
        
        if let cardIdFilter = cardIdFilter,
           !cardIdFilter.isAllowed(card.cardId) {
            throw wrongCardError
        }
    }
}

@available(iOS 13.0, *)
public extension CardFilter {
    enum ItemFilter {
        case allow(_ items: Set<String>)
        case deny(_ items: Set<String>)
        
        func isAllowed(_ item: String) -> Bool {
            switch self {
            case .allow(let items):
                return items.contains(item)
            case .deny(let items):
                return !items.contains(item)
            }
        }
    }
}
