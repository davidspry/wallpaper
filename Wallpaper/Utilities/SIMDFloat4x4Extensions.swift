//
//  SIMDFloat4x4Extensions.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import simd
import MetalKit

extension simd_float4x4 {
    static func orthographic(viewport: CGSize, near: Float, far: Float) -> simd_float4x4 {
        return orthographic(left: 0, right: Float(viewport.width), bottom: -Float(viewport.height), top: 0, near: near, far: far)
    }
    
    static func orthographic(left: Float, right: Float, bottom: Float, top: Float,
                             near: Float, far: Float) -> simd_float4x4 {
        let L = 2.0 / (right - left)
        let H = 2.0 / (top - bottom)
        let D = 1.0 / (far - near)

        return simd_float4x4([
            SIMD4<Float>(L, 0, 0, 0),
            SIMD4<Float>(0, H, 0, 0),
            SIMD4<Float>(0, 0, D, 0),
            SIMD4<Float>(0, 0, D * -near, 1)
        ])
    }
    
    func scale(_ factor: Float) -> simd_float4x4 {
        return scale(SIMD3<Float>(factor, factor, 1))
    }
    
    func scale(_ axis: SIMD3<Float>) -> simd_float4x4 {
        let columns = simd_float4x4(SIMD4<Float>(axis.x, 0, 0, 0),
                                    SIMD4<Float>(0, axis.y, 0, 0),
                                    SIMD4<Float>(0, 0, axis.z, 0),
                                    SIMD4<Float>(0, 0, 0,      1))
        
        return simd_mul(self, columns)
    }

    func translate(_ direction: SIMD3<Float>, byPixelsGivenViewportSize size: CGSize) -> simd_float4x4 {
        return translate(SIMD3<Float>(direction / SIMD3<Float>(Float(size.width), Float(size.height), 1.0)))
    }
    
    func translate(_ direction: SIMD3<Float>, byPixelsOnTexture texture: MTLTexture) -> simd_float4x4 {
        return translate(SIMD3<Float>(direction / SIMD3<Float>(Float(texture.width), Float(texture.height), 1.0)))
    }
    
    func translate(_ direction: SIMD3<Float>) -> simd_float4x4 {
        let columns = simd_float4x4(SIMD4<Float>(1, 0, 0, 0),
                                    SIMD4<Float>(0, 1, 0, 0),
                                    SIMD4<Float>(0, 0, 1, 0),
                                    SIMD4<Float>(direction.x, direction.y, direction.z, 1))
        
        return simd_mul(self, columns)
    }
}
