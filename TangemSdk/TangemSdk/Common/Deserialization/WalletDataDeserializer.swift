//
//  CardSerializer.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct WalletDataDeserializer {
    public init() {}
    
    public func deserialize(decoder: TlvDecoder) throws -> WalletData? {
        let blockchain: String? = try decoder.decode(.blockchainName)
        if blockchain == nil {
            return nil
        }
        
        return WalletData(blockchain: blockchain!,
                          token: try deserializeToken(decoder: decoder))
    }
    
    private func deserializeToken(decoder: TlvDecoder) throws -> WalletData.Token? {
        let tokenName: String? = try decoder.decode(.tokenName)
        let tokenSymbol: String? = try decoder.decode(.tokenSymbol)
        let tokenContractAddress: String? = try decoder.decode(.tokenContractAddress)
        let tokenDecimals: Int? = try decoder.decode(.tokenDecimal)
        
        if let tokenSymbol = tokenSymbol,
           let tokenContractAddress = tokenContractAddress,
           let tokenDecimals = tokenDecimals {
            return .init(name: tokenName ?? tokenSymbol,
                         symbol: tokenSymbol,
                         contractAddress: tokenContractAddress,
                         decimals: tokenDecimals)
        }
        
        return nil
    }
}
