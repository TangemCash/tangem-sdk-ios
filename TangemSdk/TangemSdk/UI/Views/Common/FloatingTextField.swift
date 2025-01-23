//
//  FloatingTextField.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 19.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine

struct FloatingTextField: View {
    let title: String
    let text: Binding<String>
    var onCommit: () -> Void = {}
    var shouldBecomeFirstResponder: Bool = false
    
    @EnvironmentObject private var style: TangemSdkStyle
    
    @ViewBuilder
    private var textField: some View {
        FocusableTextField(
            shouldBecomeFirstResponder: shouldBecomeFirstResponder,
            text: text,
            onCommit: onCommit
        )
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                ZStack(alignment: .leading) {
                    Text(title)
                        .foregroundColor(text.wrappedValue.isEmpty ? Color(.placeholderText) : style.colors.tint)
                        .offset(y: text.wrappedValue.isEmpty ? 0 : -32)
                        .scaleEffect(text.wrappedValue.isEmpty ? 1 : 0.76, anchor: .leading)
                    
                    textField
                        .keyboardType(.default)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: 17))
                        .frame(height: 17)
                }

            }
            
            Color(UIColor.opaqueSeparator)
                .frame(height: 1)
        }
        .padding(.top, 20)
        .animation(Animation.easeInOut(duration: 0.1), value: text.wrappedValue)
    }
}


struct FloatingTextField_Previews: PreviewProvider {
    @State static var text: String = "002139123"
    
    static var previews: some View {
        FloatingTextField(title: "Access code", text: $text)
            .environmentObject(TangemSdkStyle())
    }
}
