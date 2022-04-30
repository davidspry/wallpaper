//
//  SettingsPanel.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import Cocoa

class SettingsPanel: NSViewController {
    weak var mainViewController: ViewController?

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var gridView: NSGridView!
    @IBOutlet weak var tilingModeMenu: NSPopUpButton!
    @IBOutlet weak var tileSizeSlider: NSSlider!
    @IBOutlet weak var paddingSlider: NSSlider!
    @IBOutlet weak var lockAspectRatioSwitch: NSButton!
    @IBOutlet weak var imageWidthField: TextField!
    @IBOutlet weak var imageHeightField: TextField!
    @IBOutlet weak var applyImageSizeButton: NSButton!
    @IBOutlet weak var colourWell: NSColorWell!

    var aspectRatioIsLocked: Bool {
        lockAspectRatioSwitch.state == .on
    }

    private func initialiseUserSettings() {
        UserSettings.Padding = paddingSlider.floatValue
        UserSettings.TileSize = tileSizeSlider.floatValue
        UserSettings.TextureShortestSide = CGFloat(tileSizeSlider.maxValue)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let formatter = ImageSizeNumberFormatter()
        imageWidthField.formatter = formatter
        imageWidthField.stringValue = UserSettings.OutputSize.width.description
        imageWidthField.onTextChange = didUpdateImageSize(_:from:)
        
        imageHeightField.formatter = formatter
        imageHeightField.stringValue = UserSettings.OutputSize.height.description
        imageHeightField.onTextChange = didUpdateImageSize(_:from:)
        
        colourWell.color = UserSettings.ClearColour

        scrollView.documentView = gridView
        scrollView.horizontalScroller = nil
        scrollView.hasHorizontalScroller = false

        initialiseUserSettings()
    }

    private func setRendererNeedsDisplay() {
        guard let mainViewController = mainViewController,
              let metalKitView = mainViewController.metalKitView,
              let renderer = mainViewController.renderer else {
            return assertionFailure("References to the MTKView and Renderer could not be acquired.")
        }

        renderer.imageTiler.shouldRetile = true
        metalKitView.needsDisplay = true
    }

    private func updateWindowShapeToMatchImageSize() {
        guard let window = NSApplication.shared.mainWindow,
              let windowController = window.windowController as? WindowController else {
            fatalError("A reference to the WindowController could not be acquired.")
        }

        windowController.updateWindowShape(reflectingImageSize: UserSettings.OutputSize)
    }

    @IBAction func didSelectTilingMode(_ sender: NSPopUpButton) {
        guard let newTilingMode = TilingMode(rawValue: tilingModeMenu.indexOfSelectedItem), UserSettings.TilingMode != newTilingMode,
              let mainViewController = mainViewController,
              let renderer = mainViewController.renderer,
              UserSettings.TilingMode != newTilingMode else {
            return
        }

        UserSettings.TilingMode = newTilingMode
        renderer.didChangeTilingMode()
    }

    @IBAction func didChangeTileSize(_ sender: NSSlider) {
        guard UserSettings.TileSize != sender.floatValue else {
            return
        }

        UserSettings.TileSize = sender.floatValue
        setRendererNeedsDisplay()
    }

    @IBAction func didChangePadding(_ sender: NSSlider) {
        guard UserSettings.Padding != sender.floatValue else {
            return
        }

        UserSettings.Padding = sender.floatValue
        setRendererNeedsDisplay()
    }
    
    private func didUpdateImageSize(_ stringValue: String, from source: TextField) {
        guard let width = Int(imageWidthField.stringValue),
              let height = Int(imageHeightField.stringValue) else {
            applyImageSizeButton.isEnabled = false
            return
        }
        
        let newSize = CGSize(width: width, height: height)
        applyImageSizeButton.isEnabled = newSize != UserSettings.OutputSize

        if aspectRatioIsLocked, source == imageWidthField {
            let newScaledSize = CGSize(aspectRatio: UserSettings.OutputSize, withWidth: newSize.width)
            
            imageWidthField.stringValue = newScaledSize.width.description
            imageHeightField.stringValue = newScaledSize.height.description
        } else if aspectRatioIsLocked, source == imageHeightField {
            let newScaledSize = CGSize(aspectRatio: UserSettings.OutputSize, withHeight: newSize.height)
            
            imageWidthField.stringValue = newScaledSize.width.description
            imageHeightField.stringValue = newScaledSize.height.description
        } else {
            imageWidthField.stringValue = newSize.width.description
            imageHeightField.stringValue = newSize.height.description
        }
    }
    
    @IBAction func didSubmitActionFromTextField(_ sender: TextField) {
        didApplyImageSize(applyImageSizeButton)
    }
    
    @IBAction func didApplyImageSize(_ sender: NSButton) {
        guard let window = NSApp.mainWindow,
              let mainViewController = mainViewController,
              let renderer = mainViewController.renderer else {
            return assertionFailure("A reference to the renderer could not be acquired.")
        }
        
        guard let widthValue = Int(imageWidthField.stringValue),
              let heightValue = Int(imageHeightField.stringValue) else {
            return assertionFailure("The given image size is not integral.")
        }
        
        let desiredSize = CGSize(width: widthValue, height: heightValue)
        let boundedSize = aspectRatioIsLocked ?
            CGSize(aspectRatio: desiredSize, fittingWithin: UserSettings.LargestOutputSize) :
            desiredSize.bounded(between: CGSize(squareWithSize: 1)...UserSettings.LargestOutputSize)
        
        UserSettings.OutputSize = boundedSize
        imageWidthField.stringValue = boundedSize.width.description
        imageHeightField.stringValue = boundedSize.height.description

        renderer.didUpdateOutputImageSize()
        setRendererNeedsDisplay()
        applyImageSizeButton.isEnabled = false

        if window.aspectRatio.aspectRatio != UserSettings.OutputSize.aspectRatio {
            updateWindowShapeToMatchImageSize()
        }
    }

    @IBAction func didChangeClearColour(_ sender: NSColorWell) {
        guard let mainViewController = mainViewController,
              let renderer = mainViewController.renderer,
              UserSettings.ClearColour != sender.color else {
            return assertionFailure("References to the view controller and renderer could not be acquired.")
        }

        UserSettings.ClearColour = sender.color
        renderer.didChangeClearColour()
    }

}
