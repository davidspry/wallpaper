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
    
}
