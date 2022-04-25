//
//  MTLClearColorExtensions.swift
//  Wallpaper
//
//  Created by David Spry on 12/4/22.
//

import MetalKit

extension MTLClearColor {
    static func Make(from nsColor: NSColor) -> MTLClearColor {
        return Make(from: CIColor(cgColor: nsColor.cgColor))
    }
    
    static func Make(from ciColor: CIColor) -> MTLClearColor {
        return MTLClearColorMake(Double(ciColor.red),
                                 Double(ciColor.green),
                                 Double(ciColor.blue),
                                 Double(ciColor.alpha))
    }
    
    func asComponents() -> SIMD3<Float> {
        return SIMD3<Float>(Float(red), Float(green), Float(blue))
    }
}
