//
//  WindowController.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {
    weak var splitView: SplitViewController?
    @IBOutlet weak var selectSourcesButton: NSButton!
    @IBOutlet weak var toggleSidebarButton: NSButton!

    @IBAction func didPressSelectImages(_ sender: NSButton) {
        guard let splitViewController = splitView,
              let viewController = splitViewController.mainViewController else {
            return
        }

        viewController.loadImagesFromFilesystem()
    }

    @IBAction func didPressEdit(_ sender: NSButton) {
        if let delegate = NSApplication.shared.delegate as? AppDelegate {
            delegate.toggleSidebarVisibility()
        }
    }

    @IBAction func didPressSave(_ sender: NSButton) {
        guard let splitViewController = splitView,
              let viewController = splitViewController.mainViewController else {
            return
        }

        viewController.saveImageToFilesystem()
    }

    func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposedOptions: NSApplication.PresentationOptions = []) -> NSApplication.PresentationOptions {
        return [.autoHideToolbar, .autoHideMenuBar, .fullScreen]
    }

    private func configureToolbarAppearance() {
        if #available(OSX 11.0, *) {
            window?.titleVisibility = .visible

            selectSourcesButton.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "A folder.")
            toggleSidebarButton.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: "Three horizontal sliders.")

            selectSourcesButton.imagePosition = .imageLeading
            toggleSidebarButton.imagePosition = .imageLeading

            selectSourcesButton.layoutSubtreeIfNeeded()
            toggleSidebarButton.layoutSubtreeIfNeeded()
        } else {
            window?.titleVisibility = .hidden
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        configureToolbarAppearance()

        guard let window = window,
              let splitViewController = contentViewController as? SplitViewController else {
            fatalError("NSWindowController could not be initialised.")
        }

        window.delegate = self
        window.isMovableByWindowBackground = true

        splitView = splitViewController
    }

    public func useDefaultWindowSize(reflectingImageSize imageSize: NSSize) {
        guard let window = window,
              let screenFrame = NSScreen.main?.frame else {
            return
        }

        let windowRect = NSRect(size: min(imageSize, windowSize), centredIn: screenFrame)
        let windowSize = NSSize(aspectRatio: imageSize, withHeight: screenFrame.height * 0.65)

        window.aspectRatio = imageSize
        window.setFrame(windowRect, display: true, animate: true)
    }

    public func updateWindowShape(reflectingImageSize imageSize: NSSize) {
        guard let window = window,
              let screenSize = NSScreen.main?.frame.size else {
            return
        }

        let newWindowFrameWidth = min(screenSize.width * 0.65, window.frame.height / imageSize.aspectRatio)
        let newWindowFrameHeight = newWindowFrameWidth * imageSize.aspectRatio
        let newWindowFrame = NSRect(origin: window.frame.origin, size: NSSize(width: newWindowFrameWidth, height: newWindowFrameHeight))

        window.aspectRatio = imageSize
        window.setFrame(newWindowFrame, display: true, animate: true)
    }

    /// Set the window size to the given size but without accounting for macOS display scaling.
    /// - Parameter targetSize: The desired size for the window.
    
    public func updateWindowSize(matchingSize targetSize: NSSize) {
        guard let window = window,
              let screenFrame = NSScreen.main?.frame else {
            return
        }

        let deltaX = max(0, (window.frame.origin.x + targetSize.width) - screenFrame.width)
        let origin = CGPoint(x: max(0, window.frame.origin.x - deltaX),
                y: max(0, window.frame.origin.y + window.frame.height - targetSize.height))

        let newWindowFrame = NSRect(origin: origin, size: targetSize)
        window.aspectRatio = targetSize
        window.setFrame(newWindowFrame, display: true, animate: true)
    }
    
    /// Set the window size to the given size in pixels, accounting for macOS display scaling.
    /// - Parameter pixelSize: The desired size for the window in pixels.
    
    public func updateWindowSize(matchingPixelSize pixelSize: NSSize) {
        guard let window = window,
              let screen = window.screen,
              let scalingFactor = screen.scalingFactor() else {
            return
        }
        
        let targetSize = CGSize(width: pixelSize.width / scalingFactor, height: pixelSize.height / scalingFactor)
        
        updateWindowSize(matchingSize: targetSize)
    }
}
