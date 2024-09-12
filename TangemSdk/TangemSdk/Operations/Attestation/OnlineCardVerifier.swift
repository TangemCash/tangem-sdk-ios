//
//  CardVerifier.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.02.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Online verification for Tangem cards. Do not use for developer cards
public class OnlineCardVerifier {
    private let networkService: NetworkService
    
    public init(with networkService: NetworkService = .init()) {
        self.networkService = networkService
    }
    
    deinit {
        Log.debug("OnlineCardVerifier deinit")
    }
    
    /// Online verification and get info for Tangem cards. Do not use for developer cards
    /// - Parameters:
    ///   - cardId: cardId to verify
    ///   - cardPublicKey: cardPublicKey of the card
    /// - Returns: `CardVerifyAndGetInfoResponse.Item`
    public func getCardInfo(cardId: String, cardPublicKey: Data) -> AnyPublisher<CardVerifyAndGetInfoResponse.Item, Error> {
        let requestItem = CardVerifyAndGetInfoRequest.Item(cardId: cardId, publicKey: cardPublicKey.hexString)
        let request = CardVerifyAndGetInfoRequest(requests: [requestItem])
        let endpoint = TangemEndpoint.verifyAndGetInfo(request: request)

        return networkService
            .requestPublisher(endpoint)
            .tryMap { data -> CardVerifyAndGetInfoResponse in
                do {
                    return try JSONDecoder().decode(CardVerifyAndGetInfoResponse.self, from: data)
                }
                catch {
                    throw NetworkServiceError.mappingError(error)
                }
            }
            .tryMap { response in
                guard let firstResult = response.results.first else {
                    throw NetworkServiceError.emptyResponse
                }
                
                guard firstResult.passed else {
                    throw TangemSdkError.cardVerificationFailed
                }

                return firstResult
            }
            .eraseToAnyPublisher()
    }
    
    public func getCardData(cardId: String, cardPublicKey: Data) -> AnyPublisher<CardDataResponse, Error> {
        let endpoint = TangemEndpoint.cardData(cardId: cardId, cardPublicKey: cardPublicKey)

        return networkService
            .requestPublisher(endpoint)
            .tryMap { data -> CardDataResponse in
                do {
                    return try JSONDecoder.tangemSdkDecoder.decode(CardDataResponse.self, from: data)
                }
                catch {
                    throw NetworkServiceError.mappingError(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
