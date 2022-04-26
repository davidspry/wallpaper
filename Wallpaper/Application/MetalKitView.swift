//
//  MetalKitView.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import MetalKit

class MetalKitView: MTKView {
    var renderer: Renderer? {
        delegate as? Renderer
    }
    
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
    
    func useTransparentClearColour() {
        layer?.isOpaque = false
        clearColor = MTLClearColor.Make(from: NSColor.clear)
        renderer?.didChangeClearColour(to: NSColor.clear)
    }
    
    func useOpaqueClearColour() {
        layer?.isOpaque = true
        clearColor = MTLClearColor.Make(from: UserSettings.ClearColour)
        renderer?.didChangeClearColour()
    }
    
    // MARK: - Grid Pattern Background
    
    var gridBackground: GridPattern?
    
    func overlayGridBackground() {
        gridBackground = GridPattern(frame: frame)
        
        if let gridBackground = gridBackground {
            addSubview(gridBackground)
            gridBackground.pinToEdges(of: self)
        }
    }
    
    func removeGridBackground() {
        gridBackground?.removeFromSuperview()
    }
    
    // MARK: - NSDraggingDestination
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        registerForDraggedTypes([.URL, .fileURL])
    }
    
    private func canSupportDraggingOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        guard let itemUrls = draggingInfo.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        
        let fileUrls = ImageLoader.obtainAllFileUrlsFromUrls(itemUrls)
        
        return ImageLoader.urlsConainSupportedImageTypes(fileUrls)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return canSupportDraggingOperation(sender) ? .copy : .generic
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return canSupportDraggingOperation(sender)
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let itemUrls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let viewController = viewController as? ViewController else {
            return false
        }
        
        let fileURls = ImageLoader.obtainAllFileUrlsFromUrls(itemUrls)
        viewController.loadTextures(fromUrls: fileURls)
        
        return true
    }
}
