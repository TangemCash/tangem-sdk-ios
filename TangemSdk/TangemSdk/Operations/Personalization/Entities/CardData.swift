//
//  CardData.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Detailed information about card contents.
struct CardData {
    /// Tangem internal manufacturing batch ID.
    let batchId: String
    /// Timestamp of manufacturing.
    let manufactureDateTime: Date
    /// Name of the blockchain.
    let blockchainName: String
    /// Mask of products enabled on card. COS 2.30+
    let productMask: ProductMask?
    /// Name of the token.
    let tokenSymbol: String?
    /// Smart contract address.
    let tokenContractAddress: String?
    /// Number of decimals in token value.
    let tokenDecimal: Int?
}
