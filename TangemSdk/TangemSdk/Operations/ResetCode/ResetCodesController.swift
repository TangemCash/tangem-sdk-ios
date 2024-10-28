//
//  ResetCodesController.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 29.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public class ResetCodesController {
    public var cardIdDisplayFormat: CardIdDisplayFormat = .full
    
    private let resetService: ResetPinService
    private let viewDelegate: ResetCodesViewDelegate
    
    private var bag = Set<AnyCancellable>()
    private var codeType: UserCodeType? = nil
    private var completion: CompletionResult<String>? = nil
    private var newCode: String = ""
    private var cardId: String? = nil

    private var formattedCardId: String? {
        cardId.flatMap { CardIdFormatter(style: cardIdDisplayFormat).string(from: $0) }
    }
    
    init(resetService: ResetPinService, viewDelegate: ResetCodesViewDelegate) {
        self.resetService = resetService
        self.viewDelegate = viewDelegate
        bind()
    }
    
    deinit {
        Log.debug("ResetCodesController deinit")
    }
    
    public func start(codeType: UserCodeType, cardId: String?, completion: @escaping CompletionResult<String>) {
        self.cardId = cardId
        self.codeType = codeType
        self.completion = completion
        viewDelegate.setState(.requestCode(codeType, cardId: formattedCardId, completion: handleCodeInput))
    }
    
    private func bind() {
        self.resetService
            .currentStatePublisher
            .dropFirst()
            .sink {[weak self] newState in
                guard let self else { return }

                switch newState {
                case .finished:
                    self.viewDelegate.showAlert(newState.messageTitle,
                                                message: newState.messageBody,
                                                onContinue: { self.handleContinue(.success(false)) })
                default:
                    if let codeType = self.codeType {
                        self.viewDelegate.setState(.resetCodes(codeType,
                                                               state: newState,
                                                               cardId: self.formattedCardId,
                                                               completion: self.handleContinue))
                    }
                }
            }
            .store(in: &bag)
    }
    
    private func handleCodeInput(_ result: Result<String, TangemSdkError>) {
        switch result {
        case .success(let code):
            do {
                try resetService.setAccessCode(code)
                self.newCode = code
            } catch {
                viewDelegate.showError(error.toTangemSdkError())
            }
        case .failure(let error):
            viewDelegate.hide {
                self.completion?(.failure(error))
            }
        }
    }
    
    private func handleContinue(_ result: Result<Bool, TangemSdkError>){
        switch result {
        case .success(let shouldContinue):
            if shouldContinue {
                resetService.proceed(with: self.cardId)
            } else { //completed
                self.viewDelegate.hide {
                    self.completion?(.success(self.newCode))
                }
            }
        case .failure(let error):
            self.viewDelegate.hide {
                self.completion?(.failure(error))
            }
        }
    }
}
