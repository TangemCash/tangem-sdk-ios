//
//  CardView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct CardView: View {
    let cardColor: Color
    let starsColor: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(cardColor)
            .overlay(overlay)
            .aspectRatio(CGSize(width: 210, height: 130), contentMode: .fit)
    }
    
    @ViewBuilder
    private var overlay: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                
                Text("**** **** **** ****")
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .font(.system(size: 30))
                    .foregroundColor(starsColor)
                    .frame(width: 0.72 * geo.size.width)
                    .padding(.bottom, 0.1 * geo.size.height)
                    .padding(.leading, 0.1 * geo.size.width)
            }
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var cardColor = TangemSdkStyle().colors.cardColor
    
    static var previews: some View {
        Group {
            CardView(cardColor: cardColor, starsColor: .gray)
                .frame(width: 300, height: 200)
            CardView(cardColor: cardColor, starsColor: .gray)
                .preferredColorScheme(.dark)
                .frame(width: 300, height: 200)
        }
    }
}
