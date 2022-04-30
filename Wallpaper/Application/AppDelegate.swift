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
    @IBOutlet weak var sidebarVisibilityItem: NSMenuItem!
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
        let isTransparent = didToggleToolbarTransparency()
        
        if #available(OSX 11.0, *) {
            windowController?.window?.titlebarAppearsTransparent = isTransparent
            windowController?.window?.titleVisibility = isTransparent ? .hidden : .visible
        } else {
            windowController?.window?.titlebarAppearsTransparent = isTransparent
        }
        
        if let visibleItems = windowController?.window?.toolbar?.visibleItems {
            for item in visibleItems {
                item.view?.isHidden = isTransparent
            }
        }
    }
    
    @objc
    public func toggleSidebarVisibility() {
        guard let windowController = windowController,
              let splitViewController = windowController.splitView,
              let settingsPanel = splitViewController.settingsPanel,
              let settingsSplitViewItem = splitViewController.splitViewItem(for: settingsPanel) else {
            return
        }
        
        let isCollapsed = settingsSplitViewItem.isCollapsed
        let shouldBeCollapsed = didToggleSidebarVisibility()
        windowController.toggleSidebarButton.state = isCollapsed ? .on : .off
        
        if isCollapsed != shouldBeCollapsed {
            splitViewController.toggleSidebar(nil)
        }
    }
    
    @discardableResult
    private func didToggleToolbarTransparency() -> Bool {
        if toolbarVisibilityItem.state == .off {
            toolbarVisibilityItem.state = .on
            toolbarVisibilityItem.title = "Hide Toolbar"
            return false
        } else {
            toolbarVisibilityItem.state = .off
            toolbarVisibilityItem.title = "Show Toolbar"
            return true
        }
    }
    
    @discardableResult
    private func didToggleSidebarVisibility() -> Bool {
        if sidebarVisibilityItem.state == .off {
            sidebarVisibilityItem.state = .on
            sidebarVisibilityItem.title = "Hide Sidebar"
            return false
        } else {
            sidebarVisibilityItem.state = .off
            sidebarVisibilityItem.title = "Show Sidebar"
            return true
        }
    }
    
    @IBAction func didSelectMenuItem(_ sender: NSMenuItem) {
        switch sender {
        case saveImageAsItem: rootViewController?.mainViewController?.saveImageToFilesystem()
        case selectImagesItem: rootViewController?.mainViewController?.loadImagesFromFilesystem()
        case toolbarVisibilityItem: toggleToolbarTransparency()
        case sidebarVisibilityItem: toggleSidebarVisibility()
        case actualSizeItem: windowController?.updateWindowSize(matchingPixelSize: UserSettings.OutputSize)
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
                  renderer.sourceTextures.isNotEmpty else {
                return false
            }
            
            return true
        } else {
            return true
        }
    }
}
