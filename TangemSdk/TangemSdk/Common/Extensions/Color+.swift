//
//  Color+.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 11.08.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

extension Color {
    static func adaptiveColor(dark: UIColor, light: UIColor) -> Color {
        Color(UIColor.init { $0.userInterfaceStyle == .dark ? dark : light })
    }
}
