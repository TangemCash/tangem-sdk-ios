//
//  BackupCertificateProvider.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 27.12.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BackupCertificateProvider {
    private let onlineCardVerifier = OnlineCardVerifier()
    private var cancellable: AnyCancellable? = nil
    private let developmentMode: Bool

    private let sdkIssuerPrivateKey = Data(hexString: "11121314151617184771ED81F2BACF57479E4735EB1405083927372D40DA9E92")

    init(developmentMode: Bool) {
        self.developmentMode = developmentMode
    }

    func getCertificate(for cardId: String, cardPublicKey: Data, _ completion: @escaping CompletionResult<Data>) {
        loadSignature(for: cardId, cardPublicKey: cardPublicKey) { loadCompletion in
            switch loadCompletion {
            case .success(let signature):
                do {
                    let certificate = try BackupCertificateProvider.generateCertificate(cardPublicKey: cardPublicKey, issuerSignature: signature)
                    completion(.success(certificate))
                } catch {
                    completion(.failure(error.toTangemSdkError()))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func loadSignature(for cardId: String, cardPublicKey: Data, _ completion: @escaping CompletionResult<Data>) {
        if developmentMode {
            do {
                let sdkIssuerSignature = try cardPublicKey.sign(privateKey: sdkIssuerPrivateKey)
                completion(.success(sdkIssuerSignature))
            } catch {
                completion(.failure(error.toTangemSdkError()))
            }
            return
        }

        cancellable = onlineCardVerifier
            .getCardData(cardId: cardId, cardPublicKey: cardPublicKey)
            .sink(receiveCompletion: { receivedCompletion in
                if case .failure = receivedCompletion {
                    completion(.failure(.issuerSignatureLoadingFailed))
                }
            }, receiveValue: { response in
                guard let signature = response.issuerSignature else {
                    completion(.failure(.issuerSignatureLoadingFailed))
                    return
                }

                completion(.success(signature))
            })
    }

    private static func generateCertificate(cardPublicKey: Data, issuerSignature: Data) throws -> Data {
        return try TlvBuilder()
            .append(.cardPublicKey, value: cardPublicKey)
            .append(.issuerDataSignature, value: issuerSignature)
            .serialize()
    }
}
