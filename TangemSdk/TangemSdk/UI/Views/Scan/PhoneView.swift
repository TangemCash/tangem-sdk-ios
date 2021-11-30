//
//  PhoneView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
struct PhoneView: View {
    @EnvironmentObject var style: TangemSdkStyle
    
    private let notchHeight: CGFloat = 12
    private let notchCornerRadius: CGFloat = 10
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 35)
                    .inset(by: 4)
                    .stroke(style.colors.phoneStroke, lineWidth: 14)
                    .background(style.colors.phoneBackground
                                    .opacity(0.955))
                    .clipShape(RoundedRectangle(cornerRadius:35))
                
                Capsule(style: .continuous)
                    .fill(style.colors.phoneStroke)
                    .cornerRadius(notchCornerRadius)
                    .frame(width: 0.5 * geo.size.width,
                           height: 2 * notchHeight)
                    .offset(y: -geo.size.height/2 + notchHeight)
            }
        }
    }
}

@available(iOS 13.0, *)
struct PhoneView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PhoneView()
                .frame(width: 180, height: 360)
                .padding(50)
               
            
            PhoneView()
                .preferredColorScheme(.dark)
                .padding(50)
        }
        .environmentObject(TangemSdkStyle())
    }
}
