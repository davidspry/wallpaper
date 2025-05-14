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

enum UserSettings {
    static var Padding: Float = .zero
    static var TileSize: Float = .zero
    static var TextureShortestSide: CGFloat = .zero
    static var TilingMode: TilingMode = .equalWidths
    static var ClearColour: NSColor = .init(white: 0.9, alpha: 1.0)
    static var OutputSize: CGSize = .init(width: 2560, height: 1440)
    static var LargestOutputSize: CGSize = .init(width: 7680, height: 7680)
}
