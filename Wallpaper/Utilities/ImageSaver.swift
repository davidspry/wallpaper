//
//  ImageSaver.swift
//  Wallpaper
//
//  Created by David Spry on 13/4/22.
//

import Cocoa

struct ImageSaver {
    static private let imageProperties: [NSBitmapImageRep.PropertyKey: Any] = [
        .compressionFactor: NSNumber(floatLiteral: 1.0)
    ]

    static public func saveImageAsFile(_ image: NSImage) {
        guard let imageAsTiff = image.tiffRepresentation,
              let imageAsBitmap = NSBitmapImageRep(data: imageAsTiff),
              let imageAsData = imageAsBitmap.representation(using: .jpeg, properties: imageProperties),
              let window = NSApplication.shared.mainWindow else {
            return
        }

        SavePanel(overWindow: window) { panel, response in
            if response == .OK {
                guard let panelUrl = panel.url else {
                    let alert = NSAlert()
                    alert.alertStyle = .critical
                    alert.messageText = "NSSavePanel did not return a URL."
                    alert.runModal()
                    return
                }
                
                do { try imageAsData.write(to: panelUrl) } catch {
                    print("Error: Could not write tiled image to file. \(error.localizedDescription)")
                }
            }
        }
    }
    
    static private func didSetFileExtension(to fileExtension: String, forPanel panel: NSSavePanel) {
        panel.allowedFileTypes = [fileExtension]
    }

    static private func SavePanel(overWindow window: NSWindow, then handleResult: @escaping (_ panel: NSSavePanel, _ response: NSApplication.ModalResponse) -> Void) {
        let panel = NSSavePanel()
        panel.title = "Save Image"
        panel.nameFieldLabel = "Filename:"
        panel.nameFieldStringValue = "Wallpaper"
        panel.prompt = "Save"
        panel.allowedFileTypes = ["jpg"]
        panel.isExtensionHidden = false
        panel.canCreateDirectories = true
        panel.beginSheetModal(for: window) { response in
            handleResult(panel, response)
        }
    }
}
