//
//  BadgedCardView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 26.10.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct BadgedCardView: View {
    let cardColor: Color
    let starsColor: Color
    let name: String
    let badgeBackground: Color
    let badgeForeground: Color
    
    var body: some View {
        CardView(cardColor: cardColor, starsColor: starsColor)
            .overlay(overlay)
    }
    
    @ViewBuilder
    private var overlay: some View {
        GeometryReader { geo in
            HStack {
                Spacer()
                Text(name)
                    .font(.system(size: 13, weight: .semibold, design: .default))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundColor(badgeForeground)
                    .background(badgeBackground.cornerRadius(100))
                    .padding(.top, 0.15 * geo.size.height)
                    .padding(.trailing, 0.05 * geo.size.width)
            }
        }
    }
}

struct BadgedCardView_Previews: PreviewProvider {
    static var previews: some View {
        BadgedCardView(cardColor: .blue, starsColor: .gray,
                       name: "Origin card",
                       badgeBackground: .red,
                       badgeForeground: .white)
            .frame(width: 300, height: 0.6 * 300)
    }
}
