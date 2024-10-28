//
//  ResetCodesViewDelegate.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

final class ResetCodesViewDelegate: BaseViewDelegate {
    private let viewModel: ResetCodesViewModel = .init(viewState: .empty)
    private let style: TangemSdkStyle
    
    init(style: TangemSdkStyle) {
        self.style = style
    }
    
    override func makeScreen() -> UIViewController {
        let view = ResetCodesScreen()
            .environmentObject(viewModel)
            .environmentObject(style)
        
        let screen = UIHostingController(rootView: view)
        screen.isModalInPresentation = true
        return screen
    }
    
    func setState(_ state: ResetCodesViewState) {
        Log.view("Set state: \(state)")
        
        let setStateAction = { self.viewModel.viewState = state }
        runInMainThread (setStateAction())
        runInMainThread(self.presentScreenIfNeeded())
    }
    
    func hide(completion: (() -> Void)?) {
        runInMainThread(self.dismissScreen(completion: completion))
    }
    
    func showError(_ error: TangemSdkError) {
        guard let screen = screen else { return }
        
        let tint = style.colors.tintUIColor
        runInMainThread(UIAlertController.showAlert(from: screen,
                                                    title: "common_error".localized,
                                                    message: error.localizedDescription,
                                                    tint: tint,
                                                    onContinue: {}))
    }
    
    func showAlert(_ title: String, message: String, onContinue: @escaping () -> Void) {
        guard let screen = screen else {
            onContinue()
            return
        }
        
        let tint = style.colors.tintUIColor
        runInMainThread(UIAlertController.showAlert(from: screen,
                                                    title: title,
                                                    message: message,
                                                    tint: tint,
                                                    onContinue: onContinue))
    }
}
