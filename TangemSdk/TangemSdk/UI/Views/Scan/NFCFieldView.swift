//
//  NFCFieldView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 20.07.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct NFCFieldView: View {
    var isAnimationOn: Bool {
        didSet {
            circleScale = isAnimationOn ? 0.5 : 1
        }
    }
    
    @EnvironmentObject var style: TangemSdkStyle
    
    private let duration: Double = 0.9
    
    private var bigCircleAnimation: Animation {
        Animation
            .easeInOut(duration: duration)
            .repeatForever()
            .delay(0.1)
    }
    
    private var smallCircleAnimation: Animation {
        Animation
            .easeInOut(duration: duration)
            .repeatForever()
    }
    
    @State private var circleScale: CGFloat =  1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(style.colors.tint.opacity(0.2))
                    .scaleEffect(circleScale)
                    .animation(isAnimationOn ? bigCircleAnimation : nil, value: circleScale)

                Circle()
                    .fill(style.colors.tint.opacity(0.2))
                    .frame(width: 0.6 * geo.size.width,
                           height: 0.6 * geo.size.width)
                    .scaleEffect(circleScale)
                    .animation(isAnimationOn ? smallCircleAnimation : nil, value: circleScale)
            }
        }
        .onAppear() {
            circleScale = isAnimationOn ? 0.5 : 1
        }
    }
}

struct NFCView_Previews: PreviewProvider {
    @State static var animation: Bool = true
    static var previews: some View {
        Group {
            NFCFieldView(isAnimationOn: animation)
            NFCFieldView(isAnimationOn: animation)
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
