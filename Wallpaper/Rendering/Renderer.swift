//
//  Renderer.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import simd
import MetalKit

fileprivate struct Uniforms {
    var viewProjectionMatrix: simd_float4x4
}

fileprivate struct InstanceUniforms {
    var modelMatrix: simd_float4x4
}

class Renderer: NSObject, MTKViewDelegate {
    private weak var metalKitView: MTKView?
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?

    private var onscreenUniformsBuffer: MTLBuffer?
    private var onscreenRenderPipelineState: MTLRenderPipelineState?
    private var projectionMatrix = simd_float4x4(1)

    private(set) var texture: MTLTexture?
    private var offscreenTexture: MTLTexture?
    private var offscreenUniformsBuffer: MTLBuffer?
    private var offscreenRenderPipelineState: MTLRenderPipelineState?
    private var offscreenRenderPassDescriptor: MTLRenderPassDescriptor?

    let imageTiler = ImageTiler()
    var sourceTextures: [MTLTexture] {
        get { imageTiler.imageTextures }
        set { imageTiler.imageTextures = newValue }
    }

    init(withMetalKitView mtkView: MTKView) {
        super.init()
        metalKitView = mtkView
        device = mtkView.device
        commandQueue = device?.makeCommandQueue()
        onscreenUniformsBuffer = device?.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [])
        offscreenUniformsBuffer = device?.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: [])

        initialiseTexturesForOffscreenRendering()
        initialiseOffscreenRenderPipelineState()
        initialiseOnscreenRenderPipelineState()
        initialiseRenderPassDescriptorForOffscreenTexture()

        didUpdateOutputImageSize()
    }

    private func setShouldRedraw() {
        imageTiler.shouldRetile = true
        metalKitView?.needsDisplay = true
    }

    private func initialiseTexturesForOffscreenRendering() {
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = MTLTextureType.type2D
        textureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        textureDescriptor.height = Int(UserSettings.OutputSize.height)
        textureDescriptor.width = Int(UserSettings.OutputSize.width)
        textureDescriptor.usage = [MTLTextureUsage.renderTarget]
        textureDescriptor.storageMode = MTLStorageMode.managed

        let offscreenTextureDescriptor = MTLTextureDescriptor()
        offscreenTextureDescriptor.textureType = MTLTextureType.type2D
        offscreenTextureDescriptor.pixelFormat = MTLPixelFormat.bgra8Unorm
        offscreenTextureDescriptor.height = Int(UserSettings.OutputSize.height)
        offscreenTextureDescriptor.width = Int(UserSettings.OutputSize.width)
        offscreenTextureDescriptor.usage = [MTLTextureUsage.shaderRead]
        offscreenTextureDescriptor.storageMode = MTLStorageMode.private

        if let device = device {
            texture = device.makeTexture(descriptor: textureDescriptor)
            offscreenTexture = device.makeTexture(descriptor: offscreenTextureDescriptor)
        }
    }

    private func initialiseRenderPassDescriptorForOffscreenTexture() {
        guard let texture = texture else {
            return assertionFailure("A reference to the offscreen render target could not be acquired.")
        }

        offscreenRenderPassDescriptor = MTLRenderPassDescriptor()
        offscreenRenderPassDescriptor?.colorAttachments[0].texture = texture
        offscreenRenderPassDescriptor?.colorAttachments[0].loadAction = MTLLoadAction.clear
        offscreenRenderPassDescriptor?.colorAttachments[0].storeAction = MTLStoreAction.store

        didChangeClearColour()
    }

    private func fragmentShader(forMaskType maskType: MaskType) -> String {
        switch maskType {
            case .None:
                return "SampleTexture"
            case .Square:
                return "SampleTextureWithSquareMask"
            case .Circle:
                return "SampleTextureWithCircularMask"
            case .Hexagon:
                return "SampleTextureWithHexagonalMask"
        }
    }

    private func fragmentShader(forTilingMode tilingMode: TilingMode) -> String {
        switch tilingMode {
            case .equalWidths: return fragmentShader(forMaskType: .None)
            case .equalHeights: return fragmentShader(forMaskType: .None)
            case .squareGrid: return fragmentShader(forMaskType: .Square)
            case .circleGrid: return fragmentShader(forMaskType: .Circle)
            case .hexagonGrid: return fragmentShader(forMaskType: .Hexagon)
        }
    }

    private func initialiseOffscreenRenderPipelineState() {
        guard let metalKitDevice = device,
              let metalKitLibrary = metalKitDevice.makeDefaultLibrary(),
              let texture = texture else {
            fatalError()
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Offscreen Render Pipeline"
        pipelineDescriptor.vertexFunction = metalKitLibrary.makeFunction(name: "InstancedTextureVertices")
        pipelineDescriptor.fragmentFunction = metalKitLibrary.makeFunction(name: fragmentShader(forTilingMode: UserSettings.TilingMode))
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid

        pipelineDescriptor.colorAttachments[0].pixelFormat = texture.pixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .destinationAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .destinationAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusBlendAlpha

        do {
            try offscreenRenderPipelineState = metalKitDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            assertionFailure("The offscreen render pipeline state could not be initialised.")
        }
    }

    private func initialiseOnscreenRenderPipelineState() {
        guard let metalKitDevice = device,
              let metalKitLibrary = metalKitDevice.makeDefaultLibrary() else {
            fatalError()
        }

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "Onscreen Render Pipeline"
        pipelineDescriptor.sampleCount = 4
        pipelineDescriptor.vertexFunction = metalKitLibrary.makeFunction(name: "TextureVertices")
        pipelineDescriptor.fragmentFunction = metalKitLibrary.makeFunction(name: fragmentShader(forMaskType: .None))
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        do {
            try onscreenRenderPipelineState = metalKitDevice.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            assertionFailure("The render pipeline state could not be initialised.")
        }
    }

    /// Render a new frame.

    internal func draw(in view: MTKView) {
        guard let metalKitDevice = device,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }

        if imageTiler.shouldRetile {
            drawToOffscreenTexture(usingDevice: metalKitDevice)
        }

        guard let uniformsBuffer = onscreenUniformsBuffer,
              let currentDrawable = view.currentDrawable,
              let onscreenRenderPipelineState = onscreenRenderPipelineState,
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }

        commandEncoder.setRenderPipelineState(onscreenRenderPipelineState)
        commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
        commandEncoder.setFragmentTexture(offscreenTexture, index: 0)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }

    /// Compute and render the image layout to the offscreen texture.

    private func drawToOffscreenTexture(usingDevice metalKitDevice: MTLDevice) {
        guard let commandBuffer = commandQueue?.makeCommandBuffer(),
              let uniformsBuffer = offscreenUniformsBuffer,
              let offscreenRenderPipelineState = offscreenRenderPipelineState,
              let offscreenRenderPassDescriptor = offscreenRenderPassDescriptor,
              let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offscreenRenderPassDescriptor) else {
            return assertionFailure("The renderer could not create a render command encoder from the offscreen render pass descriptor.")
        }

        for tiledTexture in imageTiler.tileImages() {
            guard case let texture = tiledTexture.texture,
                  case let instances = tiledTexture.tiles, instances.isNotEmpty,
                  let imageSize = instances.first?.size else {
                continue
            }

            let aspectRatio = [Float(imageSize.width / imageSize.height)]
            let numberOfInstances = instances.count
            let modelMatricesInBytes = MemoryLayout<InstanceUniforms>.stride * numberOfInstances
            let modelMatrices = instances.map {
                InstanceUniforms(modelMatrix: $0.ModelMatrix(forOutputSize: UserSettings.OutputSize))
            }

            if modelMatricesInBytes > 4096 {
                commandEncoder.setVertexBuffer(device?.makeBuffer(bytes: modelMatrices, length: modelMatricesInBytes),
                        offset: 0, index: 1)
            } else {
                commandEncoder.setVertexBytes(modelMatrices, length: modelMatricesInBytes, index: 1)
            }

            commandEncoder.setRenderPipelineState(offscreenRenderPipelineState)
            commandEncoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 0)
            commandEncoder.setVertexBytes(aspectRatio, length: MemoryLayout<Float>.stride, index: 2)
            commandEncoder.setFragmentTexture(texture, index: 0)
            commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: numberOfInstances)
        }

        commandEncoder.endEncoding()

        guard let blitCommandEncoder = commandBuffer.makeBlitCommandEncoder(),
              let destinationTexture = offscreenTexture,
              let intermediateTexture = texture else {
            return assertionFailure("The blit command encoder could not be created.")
        }

        blitCommandEncoder.copy(from: intermediateTexture, to: destinationTexture)
        blitCommandEncoder.synchronize(resource: intermediateTexture)
        blitCommandEncoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func updateProjectionMatrix(forViewportSize newSize: CGSize) {
        let imageScaleFactor = Float(newSize.height / UserSettings.OutputSize.height)
        let widthScaleFactor = Float(UserSettings.OutputSize.width / newSize.width)
        let scaleFactor = widthScaleFactor * imageScaleFactor
        
        projectionMatrix = simd_float4x4(1).scale(SIMD3<Float>(scaleFactor, 1, 1))
    }

    /// This method will be called whenever the view's orientation or size changes.

    internal func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        updateProjectionMatrix(forViewportSize: size)
        
        if let onscreenBuffer = onscreenUniformsBuffer {
            onscreenBuffer
                .contents()
                .copyMemory(from: [projectionMatrix],
                            byteCount: MemoryLayout<Uniforms>.stride
                )
        }
    }

    // MARK: - Public Interface

    /// This method should be called when the output image size is changed in order that the correct view-projection matrix can be uploaded as a uniform.

    func didUpdateOutputImageSize() {
        if let offscreenBuffer = offscreenUniformsBuffer {
            imageTiler.didChangeOutputImageSize()
            
            offscreenBuffer
                    .contents()
                    .copyMemory(from: [imageTiler.viewProjectionMatrix],
                                byteCount: MemoryLayout<Uniforms>.stride
                    )
        }

        if sourceTextures.isNotEmpty {
            initialiseTexturesForOffscreenRendering()
            initialiseOffscreenRenderPipelineState()
            initialiseOnscreenRenderPipelineState()
            initialiseRenderPassDescriptorForOffscreenTexture()
            setShouldRedraw()
        }
    }

    /// This method should be called when the desired clear colour is changed in order that it can be propagated to the offscreen render pass descriptor.

    func didChangeClearColour() {
        if let offscreenRenderPassDescriptor = offscreenRenderPassDescriptor {
            offscreenRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.Make(from: UserSettings.ClearColour)
            setShouldRedraw()
        }
    }
    
    func didChangeClearColour(to clearColour: NSColor) {
        if let offscreenRenderPassDescriptor = offscreenRenderPassDescriptor {
            offscreenRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.Make(from: clearColour)
            setShouldRedraw()
        }
    }

    /// This method should be called when the tiling mode is changed in order that the appropriate fragment shader is selected.

    func didChangeTilingMode() {
        initialiseOffscreenRenderPipelineState()
        setShouldRedraw()
    }
}
