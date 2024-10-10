//
//  ReadView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct ReadView: View {
    @EnvironmentObject var style: TangemSdkStyle
    
    @State private var cardOffset: CGSize = .init(width: -220, height: -160)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                NFCFieldView(isAnimationOn: true)
                    .frame(width: 240, height: 240)
                    .offset(y: -160)
                
                tagView
                    .frame(minWidth: 210, maxWidth: 210)
                    .offset(cardOffset)
                    .animation(
                        Animation
                            .easeInOut(duration: 1)
                            .delay(1)
                            .repeatForever(),
                        value: cardOffset
                    )

                PhoneView()
                    .frame(width: 180, height: 360)
            }
            .frame(width: geo.size.width,
                   height: geo.size.height)
        }
        .onAppear {
            cardOffset.width = 0
        }
    }
    
    @ViewBuilder
    private var tagView: some View {
        switch style.scanTagImage {
        case .genericCard:
            CardView(cardColor: style.colors.cardColor, starsColor: style.colors.starsColor)
        case .genericRing:
            Image("ring_shape_scan")
        case .image(let uiImage, let verticalOffset):
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .offset(y: verticalOffset)
        }
    }
}

struct ReadView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ReadView()
            ReadView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
