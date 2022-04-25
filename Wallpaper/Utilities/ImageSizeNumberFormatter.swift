//
//  ImageSizeNumberFormatter.swift
//  Wallpaper
//
//  Created by David Spry on 11/4/22.
//

import Cocoa

class ImageSizeNumberFormatter: NumberFormatter {
    override func isPartialStringValid(_ partialString: String,
                                       newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
                                       errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        guard let parsedValue = Int(partialString), parsedValue > 0 else {
            return false
        }

        return true
    }
}
