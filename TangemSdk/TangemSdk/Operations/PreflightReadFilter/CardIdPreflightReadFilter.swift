//
//  CardIdPreflightReadFilter.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 09.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct CardIdPreflightReadFilter: PreflightReadFilter {
    private let expectedCardId: String

    init(cardId: String) {
        expectedCardId = cardId
    }

    func onCardRead(_ card: Card, environment: SessionEnvironment) throws {
        if expectedCardId.caseInsensitiveCompare(card.cardId) == .orderedSame {
            return
        }

        let formatter = CardIdFormatter(style: environment.config.cardIdDisplayFormat)
        let expectedCardIdFormatted = formatter.string(from: expectedCardId)
        throw TangemSdkError.wrongCardNumber(expectedCardId: expectedCardIdFormatted)
    }

    func onFullCardRead(_ card: Card, environment: SessionEnvironment) throws {}
}
