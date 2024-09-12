//
//  BaseViewDelegate.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02.11.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

class BaseViewDelegate {
    var screen: UIViewController? = nil
    
    deinit {
        Log.debug("BaseViewDelegate deinit")
    }
    
    func makeScreen() -> UIViewController {
        fatalError("You should not call base method")
    }
    
    func presentScreenIfNeeded() {
        guard self.screen == nil else {
            return
        }
        
        guard let topmostViewController = UIApplication.shared.topMostViewController else { return }
        
        if let presentedController = topmostViewController.presentedViewController { //dismiss alert
            presentedController.dismiss(animated: false) {
                DispatchQueue.main.async {
                    self.presentScreenIfNeeded()
                }
            }

            return
        }
        
        let screen = makeScreen()
        self.screen = screen
        
        topmostViewController.present(screen, animated: true, completion: nil)
    }
    
    
    func dismissScreen(completion: (() -> Void)?) {
        guard let screen = self.screen else {
            completion?()
            return
        }
        
        if screen.isBeingDismissed || screen.presentingViewController == nil {
            completion?()
            return
        }
        
        if screen.isBeingPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                screen.dismiss(animated: false, completion: {
                    self.screen = nil
                    completion?()
                })
            }
            return
        }
        
        screen.presentingViewController?.dismiss(animated: true, completion: {
            self.screen = nil
            completion?()
        })
    }
    
    func runInMainThread(_ block: @autoclosure @escaping () -> Void) {
        DispatchQueue.main.async {
            block()
        }
    }
}
