//
//  NSImageExtensions.swift
//  Wallpaper
//
//  Created by David Spry on 14/4/22.
//

import Cocoa

extension NSImage {
    var cgImage: CGImage? {
        return cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
    
    private func withLockedFocus(_ focussedScope: @escaping () -> Void) {
       lockFocus()
       focussedScope()
       unlockFocus()
   }

   convenience init(size: NSSize, _ focussedScope: @escaping () -> Void) {
       self.init(size: size)
       withLockedFocus(focussedScope)
   }
    
    func resized(withShortestSide shortestSide: CGFloat) -> NSImage? {
        return resized(to: NSSize(aspectRatio: size, withShortestSide: shortestSide))
    }
    
    func resized(to targetSize: NSSize) -> NSImage? {
        return NSImage(size: targetSize) {
            NSGraphicsContext.current?.imageInterpolation = .high
            
            let targetRect = NSRect(origin: .zero, size: targetSize)
            let sourceRect = NSRect(origin: .zero, size: self.size)
            
            self.draw(in: targetRect, from: sourceRect, operation: .copy, fraction: 1.0)
        }
    }
}
