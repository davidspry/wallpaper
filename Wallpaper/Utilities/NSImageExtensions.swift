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
        guard let representation = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }
        
        representation.size = targetSize
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: representation)
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: targetSize))
        NSGraphicsContext.restoreGraphicsState()
        
        let resizedImage = NSImage(size: targetSize)
        resizedImage.addRepresentation(representation)
        
        return resizedImage
    }
}
