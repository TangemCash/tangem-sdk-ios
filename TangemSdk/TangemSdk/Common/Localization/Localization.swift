//
//  Localizations.swift
//  TangemSdk
//
//  Created by Alexander Osokin on 02/10/2019.
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public final class Localization {
    public static var localizationsBundle: Bundle?
    
    public static func string( _ key: String, _ args: CVarArg...) -> String {
        let format = getFormat(for: key)
        return String(format: format, locale: Locale.current, arguments: args)
    }
    
    public static func getFormat(for key: String) -> String {
        if let overridedBundle = localizationsBundle {
            let format = NSLocalizedString(key,  bundle: overridedBundle, comment: "")
            if format != key {
                return format
            }
        }
        let format = NSLocalizedString(key,  bundle: .sdkBundle, comment: "")
        return format
    }
}
