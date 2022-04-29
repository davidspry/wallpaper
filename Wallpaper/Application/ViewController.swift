//
//  ViewController.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {
    var renderer: Renderer?
    weak var settingsPanel: SettingsPanel?
    @IBOutlet weak var metalKitView: MetalKitView!
    @IBOutlet weak var loadingAnimation: LoadingAnimation!
    
    override func viewDidLoad() {
        guard let nativeScreenSize = NSScreen.nativeSize() else {
            fatalError("The native size of the screen could not be determined.")
        }
        
        metalKitView.sampleCount = 4
        metalKitView.framebufferOnly = true
        metalKitView.enableSetNeedsDisplay = true
        metalKitView.device = MTLCreateSystemDefaultDevice()
        
        UserSettings.OutputSize = nativeScreenSize
        
        renderer = Renderer(withMetalKitView: metalKitView)
        renderer?.mtkView(metalKitView, drawableSizeWillChange: metalKitView.drawableSize)
        
        metalKitView.delegate = renderer
        metalKitView.useTransparentClearColour()
        
        metalKitView.overlayGridBackground()
        
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()

        updateWindowShape()
    }

    private func updateWindowShape() {
        if let window = self.view.window,
           let windowController = window.windowController as? WindowController {
            windowController.useDefaultWindowSize(reflectingImageSize: UserSettings.OutputSize)
        }
    }

    @objc func loadImagesFromFilesystem() {
        ImageLoader.loadFileUrlsFromDirectory { [weak self] fileUrls in
            self?.loadTextures(fromUrls: fileUrls)
        }
    }
    
    func loadTextures(fromUrls fileUrls: [URL]) {
        guard let renderer = renderer,
              let metalKitView = metalKitView,
              let metalKitDevice = metalKitView.device else {
            return
        }
        
        if let loadingAnimation = loadingAnimation {
            loadingAnimation.isHidden = false
            loadingAnimation.becomeVisibleAndAnimate()
        }
        
        let textureLoader = MTKTextureLoader(device: metalKitDevice)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let cgImages = ImageLoader.obtainSupportedImagesFromFileUrls(fileUrls)
            let textures = cgImages.compactMap { cgImage -> MTLTexture? in
                try? textureLoader.newTexture(cgImage: cgImage,
                                              options: [MTKTextureLoader.Option.SRGB: false,
                                                        MTKTextureLoader.Option.generateMipmaps: NSNumber(booleanLiteral: true)])
            }

            DispatchQueue.main.sync {
                if let loadingAnimation = self?.loadingAnimation {
                    loadingAnimation.stopAnimatingAndBecomeHidden()
                }
                
                if textures.isNotEmpty {
                    renderer.sourceTextures = textures
                    metalKitView.removeGridBackground()
                    metalKitView.useOpaqueClearColour()
                    metalKitView.needsDisplay = true
                }
            }
        }
    }
    
    @objc func saveImageToFilesystem() {
        DispatchQueue.main.async {
            guard let texture = self.renderer?.texture,
                  let cgImage = texture.toCGImage() else {   
                return assertionFailure("The MTLTexture could not be saved as a CGImage.")
            }

            let nsImage = NSImage(cgImage: cgImage, size: UserSettings.OutputSize)

            ImageSaver.saveImageAsFile(nsImage)
        }
    }
    
    override func rightMouseDown(with event: NSEvent) {
        guard let delegate = NSApplication.shared.delegate as? AppDelegate,
              let sourceTextures = renderer?.sourceTextures else {
            return
        }
              
        let clickMenu = NSMenu(title: "Context")
        let saveImage = NSMenuItem(title: "Save Image As...", action: #selector(saveImageToFilesystem), keyEquivalent: "s")
        let toolbarItem = NSMenuItem()
        let sidebarItem = NSMenuItem()
        
        clickMenu.autoenablesItems = false
        saveImage.isEnabled = sourceTextures.isNotEmpty
        
        toolbarItem.title = delegate.toolbarVisibilityItem.title
        toolbarItem.state = delegate.toolbarVisibilityItem.state
        toolbarItem.action = #selector(delegate.toggleToolbarTransparency)
        toolbarItem.keyEquivalent = delegate.toolbarVisibilityItem.keyEquivalent
        
        sidebarItem.title = delegate.sidebarVisibilityItem.title
        sidebarItem.state = delegate.sidebarVisibilityItem.state
        sidebarItem.action = #selector(delegate.toggleSidebarVisibility)
        sidebarItem.keyEquivalent = delegate.sidebarVisibilityItem.keyEquivalent
        
        clickMenu.addItem(withTitle: "Select Images", action: #selector(loadImagesFromFilesystem), keyEquivalent: "o")
        clickMenu.addItem(saveImage)
        clickMenu.addItem(NSMenuItem.separator())
        clickMenu.addItem(toolbarItem)
        clickMenu.addItem(sidebarItem)
        
        NSMenu.popUpContextMenu(clickMenu, with: event, for: metalKitView)
    }
}
