//
//  FocusableTextField.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.10.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct FocusableTextField: View {
    let shouldBecomeFirstResponder: Bool
    let text: Binding<String>
    var onCommit: () -> Void = {}

    @FocusState private var focusedField: Field?
    @StateObject private var model: FocusableTextFieldModel = .init()

    var body: some View {
        SecureField("", text: text, onCommit: onCommit)
            .focused($focusedField, equals: .secure)
            .keyboardType(.default)
            .writingToolsBehaviorDisabled()
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onAppear(perform: model.onAppear)
            .onReceive(model.focusPublisher) { _ in
                if shouldBecomeFirstResponder {
                    focusedField = .secure
                }
            }
    }

    init(shouldBecomeFirstResponder: Bool,
         text: Binding<String>,
         onCommit: @escaping () -> Void = {}
    ) {
        self.shouldBecomeFirstResponder = shouldBecomeFirstResponder
        self.text = text
        self.onCommit = onCommit
    }
}


private extension FocusableTextField {
    enum Field: Hashable {
        case secure
    }
}

fileprivate class FocusableTextFieldModel: ObservableObject {
    var focusPublisher: PassthroughSubject<Void, Never> = .init()

    private var appearPublisher: CurrentValueSubject<Bool, Never> = .init(false)
    private var activePublisher: CurrentValueSubject<Bool, Never> = .init(UIApplication.shared.isActive)
    private var bag: Set<AnyCancellable> = .init()

    private var becomeActivePublisher: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// This is the minimum allowable delay, calculated empirically for all iOS versions prior 16.
    private var appearDelay: Int {
        if #available(iOS 16.0, *) {
            return 0
        } else {
            return 500
        }
    }

    init() {
        bind()
    }

    func onAppear() {
        appearPublisher.send(true)
    }

    private func bind() {
        becomeActivePublisher
            .sink { [weak self] _ in
                self?.activePublisher.send(true)
            }
            .store(in: &bag)

        appearPublisher
            .filter { $0 }
            .delay(for: .milliseconds(appearDelay), scheduler: DispatchQueue.main)
            .combineLatest(activePublisher.filter{ $0 })
            .sink { [weak self] _ in
                self?.focusPublisher.send(())
            }
            .store(in: &bag)
    }
}

fileprivate extension UIApplication {
    var isActive: Bool {
        applicationState == .active
    }
}

fileprivate extension View {
    @ViewBuilder
    func writingToolsBehaviorDisabled() -> some View {
        if #available(iOS 18.0, *) {
            self.writingToolsBehavior(.disabled)
        } else {
            self
        }
    }
}
