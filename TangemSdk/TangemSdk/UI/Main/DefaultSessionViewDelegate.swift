//
//  DefaultSessionViewDelegate.swift
//  TangemSdk
//
//  Created by Andrew Son on 02/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

final class DefaultSessionViewDelegate: BaseViewDelegate {
    private let reader: CardReader
    private let engine: HapticsEngine
    private var pinnedMessage: String?
    private var style: TangemSdkStyle
    private let viewModel: MainViewModel = .init(viewState: .scan)
    
    init(reader: CardReader, style: TangemSdkStyle) {
        self.reader = reader
        self.engine = HapticsEngine()
        self.style = style
        engine.create()
    }
    
    override func makeScreen() -> UIViewController {
        let view = MainScreen()
            .environmentObject(viewModel)
            .environmentObject(style)
        
        let screen = UIHostingController(rootView: view)
        screen.modalPresentationStyle = .overFullScreen
        screen.modalTransitionStyle = .crossDissolve
        return screen
    }
}

extension DefaultSessionViewDelegate: SessionViewDelegate {
    func setState(_ state: SessionViewState) {
        Log.view("Set state: \(state)")
        if state.shouldPlayHaptics {
            engine.playTick()
        }
        
        let setStateAction = { self.viewModel.viewState = state }
        runInMainThread (setStateAction())
        runInMainThread(self.presentScreenIfNeeded())
    }
    
    func showAlertMessage(_ text: String) {
        Log.view("Show alert message: \(text)")
        reader.alertMessage = text
    }
    
    func tagConnected() {
        Log.view("Tag connected")
        if let pinnedMessage = pinnedMessage {
            showAlertMessage(pinnedMessage)
            self.pinnedMessage = nil
        }
        engine.playSuccess()
    }
    
    func tagLost(message: String) {
        Log.view("Tag lost")
        if pinnedMessage == nil {
            pinnedMessage = reader.alertMessage
        }
        showAlertMessage(message)
    }
    
    func wrongCard(message: String) {
        Log.view("Wrong card detected")
        engine.playError()
        if pinnedMessage == nil {
            pinnedMessage = reader.alertMessage
        }
        showAlertMessage(message)
    }
    
    func sessionStarted() {
        Log.view("Session started")
        runInMainThread(self.presentScreenIfNeeded())
        engine.start()
    }
    
    func sessionStopped(completion: (() -> Void)?) {
        Log.view("Session stopped")
        pinnedMessage = nil
        engine.stop()
        runInMainThread(self.dismissScreen(completion: completion))
    }
    
    //TODO: Refactor UI
    func attestationDidFail(isDevelopmentCard: Bool, onContinue: @escaping () -> Void, onCancel: @escaping () -> Void) {
        guard let screen = screen else {
            onCancel()
            return
        }
        
        let title = "attestation_failed_card_title".localized
        let message = isDevelopmentCard ? "attestation_failed_dev_card".localized
            : "attestation_failed_card".localized
        let tint = style.colors.tintUIColor
        
        runInMainThread(UIAlertController.showShouldContinue(from: screen,
                                                             title: title,
                                                             message: message,
                                                             tint: tint,
                                                             onContinue: onContinue,
                                                             onCancel: onCancel))
    }
    
    //TODO: Refactor UI
    func attestationCompletedOffline(onContinue: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void) {
        guard let screen = screen else {
            onCancel()
            return
        }
        
        let title =  "attestation_online_failed_title".localized
        let message = "attestation_online_failed_body".localized
        let tint = style.colors.tintUIColor
        
        runInMainThread(UIAlertController.showShouldContinue(from: screen,
                                                             title: title,
                                                             message: message,
                                                             tint: tint,
                                                             onContinue: onContinue,
                                                             onCancel: onCancel,
                                                             onRetry: onRetry))
    }
    
    //TODO: Refactor UI
    func attestationCompletedWithWarnings(onContinue: @escaping () -> Void) {
        guard let screen = screen else {
            onContinue()
            return
        }
        
        let title = "common_warning".localized
        let message = "attestation_warning_attest_wallets".localized
        let tint = style.colors.tintUIColor
        runInMainThread(UIAlertController.showAlert(from: screen,
                                                    title: title,
                                                    message: message,
                                                    tint: tint,
                                                    onContinue: onContinue))
    }
}
