//
//  IndicatorView.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 16.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct IndicatorView: View {
    var state: ViewState = .spinner
    
    @EnvironmentObject var style: TangemSdkStyle
    
    @State private var angle = -90.0
    
    private var bgCircleHidden: Bool {
        switch state  {
        case .spinner:
            return true
        default:
            return false
        }
    }
    
    private var trimValue: CGFloat {
        switch state  {
        case .spinner:
            return 0.9
        case .delay(let currentValue, let totalValue):
            return 1.0 - (totalValue - currentValue)/totalValue
        case .progress(let progress):
            return CGFloat(progress)/100.0
        }
    }
    
    private var rotateAnimation: Animation {
        switch state  {
        case .spinner:
            return Animation.linear(duration: 1.3)
                .repeatForever(autoreverses: false)
        default:
            return Animation.easeOut(duration: 0.3)
        }
    }
    
    private var trimAnimation: Animation {
        switch state  {
        case .spinner:
            return Animation.linear
        default:
            return Animation.spring(dampingFraction: 0.7).speed(1.6)
        }
    }
    
    private var rotationAngle: Angle {
        switch state  {
        case .spinner:
            return Angle(degrees: angle)
        default:
            return Angle(degrees: -90)
        }
    }
    
    private var labelText: String? {
        switch state  {
        case .spinner:
            return nil
        case .delay(let currentValue, _):
            let intValue = Int(currentValue)
            return "\(intValue)"
        case .progress(let progress):
            return "\(progress)%"
        }
    }
    
    var body: some View {
        ZStack {
            if !bgCircleHidden {
                Circle()
                    .stroke(style.colors.indicatorBackground,
                            lineWidth: CGFloat(style.indicatorWidth))
            }
            
            Circle()
                .trim(from: 0, to: trimValue)
                .stroke(style.colors.tint,
                        lineWidth: CGFloat(style.indicatorWidth))
                .animation(trimAnimation, value: trimValue)
                .rotationEffect(rotationAngle)
                .animation(rotateAnimation, value: rotationAngle)
            
            if let text = labelText {
                Text(text)
                    .font(.system(size: style.textSizes.indicatorLabel,
                                  weight: .medium,
                                  design: .default))
                    .foregroundColor(style.colors.tint)
            }
        }
        .padding(.all, CGFloat(style.indicatorWidth)/2)
        .onAppear {
            angle = 270
        }
    }
}

extension IndicatorView {
    enum ViewState {
        case spinner
        case delay(currentValue: CGFloat, totalValue: CGFloat)
        case progress(progress: Int)
    }
}

struct SpinnerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IndicatorView(state: .spinner)
            IndicatorView(state: .progress(progress: 30))
            IndicatorView(state: .delay(currentValue: 14, totalValue: 15))
            IndicatorView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(TangemSdkStyle())
    }
}
