//
//  NSScreenExtensions.swift
//  Wallpaper
//
//  Created by David Spry on 25/4/2022.
//

import Cocoa

extension NSScreen {
    static func nativeSize() -> NSSize? {
        let displayId = CGMainDisplayID()
        
        guard let displayModes = CGDisplayCopyAllDisplayModes(displayId, nil) as? [CGDisplayMode],
              let nativeDisplayMode = displayModes
            .filter({ displayMode in displayMode.width == displayMode.pixelWidth})
            .max(by: { a, b in a.pixelWidth < b.pixelWidth}) else {
                return nil
        }
        
        return NSSize(width: nativeDisplayMode.pixelWidth, height: nativeDisplayMode.pixelHeight)
    }
}
