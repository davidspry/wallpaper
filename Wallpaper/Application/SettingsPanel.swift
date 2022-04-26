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
    @IBOutlet weak var imageWidthField: NSTextField!
    @IBOutlet weak var imageHeightField: NSTextField!
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
        imageHeightField.formatter = formatter
        imageWidthField.stringValue = UserSettings.OutputSize.width.description
        imageHeightField.stringValue = UserSettings.OutputSize.height.description
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

    @IBAction func didChangeImageSize(_ sender: NSTextField) {
        guard let mainViewController = mainViewController,
              let renderer = mainViewController.renderer else {
            return assertionFailure("A reference to the renderer could not be acquired.")
        }

        guard let widthValue = Int(imageWidthField.stringValue),
              let heightValue = Int(imageHeightField.stringValue) else {
            return assertionFailure("The given image size is not integral.")
        }

        guard case let width = max(1, min(UserSettings.LargestOutputSize.width, CGFloat(widthValue))),
              case let height = max(1, min(UserSettings.LargestOutputSize.height, CGFloat(heightValue))),
              case let newSize = CGSize(width: width, height: height),
              newSize != UserSettings.OutputSize else {
            return
        }

        let newAspectRatio = newSize.aspectRatio
        let previousAspectRatio = UserSettings.OutputSize.aspectRatio

        if aspectRatioIsLocked, sender == imageWidthField {
            UserSettings.OutputSize.width = newSize.width
            UserSettings.OutputSize.height = newSize.width * previousAspectRatio
        } else if aspectRatioIsLocked, sender == imageHeightField {
            UserSettings.OutputSize.height = newSize.height
            UserSettings.OutputSize.width = newSize.height / previousAspectRatio
        } else {
            UserSettings.OutputSize = newSize
        }

        imageWidthField.stringValue = UserSettings.OutputSize.width.description
        imageHeightField.stringValue = UserSettings.OutputSize.height.description

        renderer.didUpdateOutputImageSize()
        setRendererNeedsDisplay()

        if newAspectRatio != previousAspectRatio {
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
