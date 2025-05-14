//
//  SplitViewController.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import Cocoa

class SplitViewController: NSSplitViewController {
    weak var settingsPanel: SettingsPanel?
    weak var mainViewController: ViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        guard splitViewItems.count > 1,
              let mainViewController = splitViewItems[0].viewController as? ViewController,
              let settingsPanel = splitViewItems[1].viewController as? SettingsPanel
        else {
            fatalError("SplitViewController did not initialise correctly.")
        }

        self.settingsPanel = settingsPanel
        self.mainViewController = mainViewController

        self.settingsPanel?.mainViewController = mainViewController
        self.mainViewController?.settingsPanel = settingsPanel

        splitViewItem(for: settingsPanel)?.minimumThickness = 320
        splitViewItem(for: settingsPanel)?.maximumThickness = 320
    }
}
