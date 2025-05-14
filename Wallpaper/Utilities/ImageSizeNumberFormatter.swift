//
//  ImageSizeNumberFormatter.swift
//  Wallpaper
//
//  Created by David Spry on 11/4/22.
//

import Cocoa

class ImageSizeNumberFormatter: NumberFormatter {
    override func isPartialStringValid(_ partialString: String,
                                       newEditingString _: AutoreleasingUnsafeMutablePointer<NSString?>?,
                                       errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool
    {
        guard let parsedValue = Int(partialString), parsedValue > 0 else {
            return partialString.isEmpty
        }

        return true
    }
}
