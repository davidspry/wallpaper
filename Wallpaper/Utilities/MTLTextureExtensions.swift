//
//  MTLTextureExtensions.swift
//  Wallpaper
//
//  Created by David Spry on 12/4/22.
//

import MetalKit

extension MTLTexture {
    func toCGImage() -> CGImage? {
        let bytesPerPixel = 4
        let rowSizeInBytes = bytesPerPixel * width
        let textureSizeInBytes = rowSizeInBytes * height
        var textureBytes = [UInt8](repeating: 0, count: textureSizeInBytes)

        textureBytes.withUnsafeMutableBytes { rawBufferPointer in
            guard let arrayPointer = rawBufferPointer.baseAddress else {
                return
            }

            getBytes(arrayPointer,
                     bytesPerRow: width * 4,
                     from: MTLRegionMake2D(0, 0, width, height),
                     mipmapLevel: 0)
        }

        guard let imageData = CFDataCreate(nil, textureBytes, textureSizeInBytes),
              let imageDataProvider = CGDataProvider(data: imageData)
        else {
            return nil
        }

        return CGImage(width: width,
                       height: height,
                       bitsPerComponent: 8,
                       bitsPerPixel: bytesPerPixel * 8,
                       bytesPerRow: rowSizeInBytes,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                       provider: imageDataProvider,
                       decode: nil,
                       shouldInterpolate: true,
                       intent: CGColorRenderingIntent.defaultIntent)
    }
}
