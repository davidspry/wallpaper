//
//  UserSettings.swift
//  Wallpaper
//
//  Created by David Spry on 11/4/22.
//

import Cocoa

enum MaskType {
    case None
    case Square
    case Circle
    case Hexagon
}

enum TilingMode: Int {
    case equalWidths
    case equalHeights
    case squareGrid
    case circleGrid
    case hexagonGrid
}

struct UserSettings {
    static var Padding: Float = 16
    static var TileSize: Float = 200
    static var TextureShortestSide: CGFloat = 1056
    static var OutputSize: CGSize = CGSize(width: 2560, height: 1440)
    static var LargestOutputSize: CGSize = CGSize(width: 7680, height: 7680)
    static var TilingMode: TilingMode = .equalWidths
    static var ClearColour: NSColor = NSColor(white: 0.9, alpha: 1.0)
}
