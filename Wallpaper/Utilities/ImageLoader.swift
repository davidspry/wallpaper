//
//  ImageLoader.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import Cocoa

struct ImageLoader {
    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "heic", "tif", "tiff", "pdf"]

    public static func loadFileUrlsFromDirectory(then provideResults: @escaping ([URL]) -> Void) {
        if let window = NSApplication.shared.mainWindow {
            OpenPanel(overWindow: window) { panel, response in
                if response == .OK {
                    let fileUrls = obtainAllFileUrlsFromUrls(panel.urls)
                        .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                    provideResults(fileUrls)
                }
            }
        }
    }
    
    public static func loadImagesFromDirectory(then provideResults: @escaping ([CGImage]) -> Void) {
        if let window = NSApplication.shared.mainWindow {
            OpenPanel(overWindow: window) { panel, response in
                if response == .OK {
                    let fileUrls = obtainAllFileUrlsFromUrls(panel.urls)
                        .sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
                    let images = obtainSupportedImagesFromFileUrls(fileUrls)
                    provideResults(images)
                }
            }
        }
    }

    private static func OpenPanel(overWindow window: NSWindow,
                                  then handleResult: @escaping (_ panel: NSOpenPanel, _ response: NSApplication.ModalResponse) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.allowedFileTypes = [String](imageExtensions)
        panel.beginSheetModal(for: window) { response in
            handleResult(panel, response)
        }
    }
    
    public static func obtainAllFileUrlsFromUrls(_ urls: [URL]) -> [URL] {
        urls
            .compactMap { url in
                if url.hasDirectoryPath {
                    return obtainUrlsFromDirectory(withUrl: url)
                } else if url.isFileURL {
                    return [url]
                } else {
                    return nil
                }
            }
            .reduce([], +)
    }
    
    public static func urlsConainSupportedImageTypes(_ urls: [URL]) -> Bool {
        urls.filter { imageExtensions.contains($0.pathExtension) }.isNotEmpty
    }
    
    private static func obtainUrlsFromDirectory(withUrl directory: URL) -> [URL]? {
        try? FileManager.default
                .contentsOfDirectory(at: directory,
                        includingPropertiesForKeys: nil,
                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants, .skipsPackageDescendants])
                .filter { url in
                    imageExtensions.contains(url.pathExtension.lowercased())
                }
    }
    
    public static func obtainSupportedImagesFromFileUrls(_ urls: [URL]) -> [CGImage] {
        urls.compactMap { fileUrl in
            NSImage(contentsOf: fileUrl.absoluteURL)?
                .resized(withShortestSide: UserSettings.TextureShortestSide)?
                .cgImage
        }.filter { $0.width < 16384 && $0.height < 16384 }
    }
}
