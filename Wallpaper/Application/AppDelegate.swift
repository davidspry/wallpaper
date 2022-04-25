//
//  AppDelegate.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    var windowController: WindowController? {
        guard let window = NSApplication.shared.mainWindow,
              let windowController = window.windowController as? WindowController else {
            return nil
        }

        return windowController
    }
    
    var rootViewController: SplitViewController? {
        guard let window = NSApplication.shared.mainWindow,
              let viewController = window.contentViewController as? SplitViewController else {
            return nil
        }

        return viewController
    }

    @IBOutlet weak var selectImagesItem: NSMenuItem!
    @IBOutlet weak var saveImageAsItem: NSMenuItem!
    @IBOutlet weak var toolbarVisibilityItem: NSMenuItem!
    @IBOutlet weak var actualSizeItem: NSMenuItem!
    @IBOutlet weak var defaultSizeItem: NSMenuItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc
    public func toggleToolbarTransparency() {
        windowController?.window?.titlebarAppearsTransparent = didToggleToolbarTransparency()
    }
    
    @discardableResult
    private func didToggleToolbarTransparency() -> Bool {
        if toolbarVisibilityItem.state == .off {
            toolbarVisibilityItem.state = .on
            toolbarVisibilityItem.title = "Show Toolbar"
            return true
        } else {
            toolbarVisibilityItem.state = .off
            toolbarVisibilityItem.title = "Hide Toolbar"
            return false
        }
    }
    
    @IBAction func didSelectMenuItem(_ sender: NSMenuItem) {
        switch sender {
        case saveImageAsItem: rootViewController?.mainViewController?.saveImageToFilesystem()
        case selectImagesItem: rootViewController?.mainViewController?.loadImagesFromFilesystem()
        case toolbarVisibilityItem: toggleToolbarTransparency()
        case actualSizeItem: windowController?.updateWindowSize(matchingImageSize: UserSettings.OutputSize)
        case defaultSizeItem: windowController?.useDefaultWindowSize(reflectingImageSize: UserSettings.OutputSize)
        default: return
        }
    }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem == actualSizeItem ||
            menuItem == defaultSizeItem ||
            menuItem == saveImageAsItem {
            guard let mainViewController = rootViewController?.mainViewController,
                  let renderer = mainViewController.renderer,
                  !renderer.sourceTextures.isEmpty else {
                return false
            }
            
            return true
        } else {
            return true
        }
    }
}
