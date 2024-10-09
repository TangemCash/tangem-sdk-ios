//
//  TangemSdkStyle.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

public class TangemSdkStyle: ObservableObject {
    public var colors: Colors = .default
    public var textSizes: TextSizes = .default
    public var indicatorWidth: Float = 12
    public var scanTagImage: ScanTagImage = .genericCard
    
    public static var `default`: TangemSdkStyle = .init()
}

public extension TangemSdkStyle {
    struct Colors {
        /// Tint color of the interface. Note that due to the inability to convert SwiftUI.Color to UIKit.UIColor you have to set the two separately
        public var tint: Color = .blue
        public var tintUIColor: UIColor = .blue
        
        public var errorTint: Color = .red
        
        public var buttonColors: ButtonColors = .init()
        
        public var secondaryButtonColors: ButtonColors = .init(foregroundColor: .adaptiveColor(dark: UIColor.lightGray,
                                                                                               light: UIColor.LightPalette.secondaryButtonForeground),
                                                               backgroundColor: .adaptiveColor(dark: UIColor.systemGray3,
                                                                                               light: UIColor.LightPalette.secondaryButtonBackground),
                                                               disabledForegroundColor: Color(UIColor.systemGray2),
                                                               disabledBackgroundColor: Color(UIColor.systemGray5))
        
        public var indicatorBackground: Color = .adaptiveColor(dark: .darkGray, light: UIColor.LightPalette.indicatorBackground)
        
        public var phoneBackground: Color = .adaptiveColor(dark: .black, light: .white)
        
        public var phoneStroke: Color = .adaptiveColor(dark: .white, light: .black)
        
        public var cardColor: Color = .adaptiveColor(dark: UIColor.DarkPalette.cardColor, light: UIColor.LightPalette.cardColor)
        
        public var starsColor: Color = Color(UIColor.systemGray5) //Card's stars
        
        public static var `default`: Colors = .init()
    }
    
    struct ButtonColors {
        public var foregroundColor: Color = .white
    
        public var backgroundColor: Color = .blue
        
        public var disabledForegroundColor: Color = .gray
        
        public var disabledBackgroundColor: Color = Color(UIColor.systemGray5)
    }
}

public extension TangemSdkStyle {
    struct TextSizes {
        public var indicatorLabel: CGFloat = 50
        
        public static var `default`: TextSizes = .init()
    }
}

public extension TangemSdkStyle {
    /// Options for displaying different tags on the scanning screen
    enum ScanTagImage {
        /// Generic card provided by the SDK
        case genericCard

        /// Generic ring provided by the SDK
        case genericRing

        /// A custom tag made out of a UIImage instance.
        /// The image can be shifted vertically from the standard position by specifying `verticalOffset`.
        /// Note that the width of the image will be limited to a certain size, while the height will be determined by the aspect ratio of the image.
        /// The value of the width can be found in ReadView.swift and is 210 points at the time of the writing.
        case image(uiImage: UIImage, verticalOffset: Double)
    }
}
