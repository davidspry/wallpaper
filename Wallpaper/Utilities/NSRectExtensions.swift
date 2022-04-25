//
//  NSRect.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import Cocoa

extension NSRect {
    var centre: CGPoint {
        CGPoint(x: width * 0.5, y: height * 0.5)
    }

    init(size: NSSize, centredIn bounds: NSRect) {
        self.init(origin: NSRect.ObtainOriginByCentring(size: size, inBounds: bounds), size: size)
    }
    
    static func ObtainOriginByCentring(size: NSSize, inBounds bounds: NSRect) -> CGPoint {
        CGPoint(x: (bounds.width - size.width) * 0.5, y: (bounds.height - size.height) * 0.5)
    }
    
    static func Centre(size: NSSize, inBounds bounds: NSRect) -> NSRect {
        NSRect(origin: NSRect.ObtainOriginByCentring(size: size, inBounds: bounds), size: size)
    }
    
    static func AspectFit(_ aspectRatio: NSSize, withinBounds bounds: NSRect) -> NSRect {
        Centre(size: NSSize(aspectRatio: aspectRatio, withShortestSide: bounds.size.shortestDimension), inBounds: bounds)
    }
}
