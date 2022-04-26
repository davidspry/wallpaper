//
//  GridPattern.swift
//  Wallpaper
//
//  Created by David Spry on 26/4/22.
//

import Cocoa

class GridPattern: NSView {
    override func draw(_ dirtyRect: NSRect) {
        guard let _ = NSGraphicsContext.current?.cgContext else {
            return
        }
        
        let size = CGFloat(10)
        let rows = Int(ceil(bounds.height / size))
        let cols = Int(ceil(bounds.width / size))
        let path = NSBezierPath()
        let outerSize = 8
        
        path.lineWidth = 2.0
        path.lineJoinStyle = .round
        NSColor.systemGray.withAlphaComponent(0.05).setStroke()
        
        for row in 1..<rows {
            let source = NSPoint(x: 0, y: CGFloat(row) * size - 0.5)
            let target = NSPoint(x: bounds.width, y: CGFloat(row) * size - 0.5)
            
            path.move(to: source)
            path.line(to: target)
        }
        
        for col in 1..<cols {
            let source = NSPoint(x: CGFloat(col) * size - 0.5, y: 0)
            let target = NSPoint(x: CGFloat(col) * size - 0.5, y: bounds.height)
            
            path.move(to: source)
            path.line(to: target)
        }
        
        path.stroke()
        path.removeAllPoints()
        
        NSColor.systemGray.withAlphaComponent(0.1).setStroke()
        
        for row in stride(from: outerSize, to: rows, by: outerSize) {
            let source = NSPoint(x: 0, y: CGFloat(row) * size - 0.5)
            let target = NSPoint(x: bounds.width, y: CGFloat(row) * size - 0.5)
            
            path.move(to: source)
            path.line(to: target)
        }
        
        for col in stride(from: outerSize, to: cols, by: outerSize) {
            let source = NSPoint(x: CGFloat(col) * size - 0.5, y: 0)
            let target = NSPoint(x: CGFloat(col) * size - 0.5, y: bounds.height)
            
            path.move(to: source)
            path.line(to: target)
        }
        
        path.stroke()
        
        super.draw(dirtyRect)
    }
}
