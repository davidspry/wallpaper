//
//  ImageTiler.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import simd
import MetalKit

struct TextureInstance {
    var tiles: [Tile] = []
    weak var texture: MTLTexture?

    init?(_ metalTexture: MTLTexture?) {
        guard let metalTexture = metalTexture else {
            return nil
        }

        texture = metalTexture
    }
}

struct Tile {
    var size: CGSize
    var origin: CGPoint

    public func ModelMatrix(forOutputSize outputSize: CGSize) -> simd_float4x4 {
        matrix_identity_float4x4
                .translate(SIMD3<Float>(Float(origin.x + (size.width - outputSize.width) / 2.0),
                                        Float(origin.y + (size.height - outputSize.height) / 2.0), 0))
                .scale(SIMD3<Float>(Float(size.width / 2.0), Float(size.height / 2.0), 1.0))
    }
}

class ImageTiler {
    var shouldRetile = true
    var viewProjectionMatrix = matrix_identity_float4x4
    var tiledTextures = [TextureInstance]()
    var imageTextures = [MTLTexture]() {
        didSet { shouldRetile = true }
    }

    public func didChangeOutputImageSize() {
        viewProjectionMatrix = simd_float4x4.orthographic(viewport: UserSettings.OutputSize, near: -1, far: 1)
    }

    public func tileImages() -> [TextureInstance] {
        guard shouldRetile, !imageTextures.isEmpty else {
            return tiledTextures
        }

        switch UserSettings.TilingMode {
            case .equalWidths: tileImagesWithEqualWidths()
            case .equalHeights: tileImagesWithEqualHeights()
            case .squareGrid: tileImagesAsGridWithEqualShortestSides()
            case .circleGrid: tileImagesAsGridWithEqualShortestSides()
            case .hexagonGrid: tileImagesAsInterlockingHexagonalGrid()
        }

        return tiledTextures
    }
}

// MARK: - Tiling Implementations

// MARK: - Layout with Equal Widths

extension ImageTiler {
    internal func tileImagesWithEqualWidths() {
        tiledTextures = imageTextures.compactMap(TextureInstance.init)

        let tileWidth = UserSettings.TileSize + UserSettings.Padding
        let numbedOfColumns = Int(ceil((Float(UserSettings.OutputSize.width) + UserSettings.Padding) / tileWidth))
        let contentWidth = UserSettings.Padding + Float(numbedOfColumns) * tileWidth

        var textureIndex = 0
        var origin = CGPoint(x: (UserSettings.OutputSize.width - CGFloat(contentWidth)) / 2.0, y: 0)
        var offset = UserSettings.Padding

        for column in 0..<numbedOfColumns {
            var columnHeight = UserSettings.Padding
            var numberOfImages = 0
            let originalTextureIndex = textureIndex

            while columnHeight < Float(UserSettings.OutputSize.height) {
                let texture = imageTextures[textureIndex]
                let aspect = Float(texture.height) / Float(texture.width)
                let height = UserSettings.TileSize * aspect

                columnHeight += height + UserSettings.Padding
                numberOfImages += 1

                textureIndex += 1
                textureIndex %= imageTextures.count
            }

            textureIndex = originalTextureIndex
            origin.y = CGFloat(Float(UserSettings.OutputSize.height) - columnHeight) / 2.0
            let columnDelta = CGFloat(UserSettings.Padding) + CGFloat(column) * CGFloat(tileWidth)

            for _ in 0..<numberOfImages {
                let texture = imageTextures[textureIndex]
                let aspect = Float(texture.height) / Float(texture.width)
                let height = UserSettings.TileSize * aspect

                let textureSize = CGSize(width: CGFloat(UserSettings.TileSize), height: CGFloat(height))
                let textureOrigin = CGPoint(x: origin.x + columnDelta, y: origin.y + CGFloat(offset))
                let textureInstance = Tile(size: textureSize, origin: textureOrigin)

                tiledTextures[textureIndex].tiles.append(textureInstance)

                offset += height + UserSettings.Padding

                textureIndex += 1
                textureIndex %= imageTextures.count
            }

            offset = UserSettings.Padding
        }

        shouldRetile = false
    }
}

// MARK: - Layout with Equal Heights

extension ImageTiler {
    internal func tileImagesWithEqualHeights() {
        tiledTextures = imageTextures.compactMap(TextureInstance.init)

        let tileHeight = UserSettings.TileSize + UserSettings.Padding
        let numbedOfRows = Int(ceil((Float(UserSettings.OutputSize.height) + UserSettings.Padding) / tileHeight))
        let contentHeight = UserSettings.Padding + Float(numbedOfRows) * tileHeight

        var textureIndex = 0
        var origin = CGPoint(x: 0, y: (UserSettings.OutputSize.height - CGFloat(contentHeight)) / 2.0)
        var offset = UserSettings.Padding

        for row in 0..<numbedOfRows {
            var rowWidth = UserSettings.Padding
            var numberOfImages = 0
            let originalTextureIndex = textureIndex

            while rowWidth < Float(UserSettings.OutputSize.width) {
                let texture = imageTextures[textureIndex]
                let aspect = Float(texture.width) / Float(texture.height)
                let width = UserSettings.TileSize * aspect

                rowWidth += width + UserSettings.Padding
                numberOfImages += 1

                textureIndex += 1
                textureIndex %= imageTextures.count
            }

            textureIndex = originalTextureIndex
            origin.x = CGFloat(Float(UserSettings.OutputSize.width) - rowWidth) / 2.0
            let rowDelta = CGFloat(UserSettings.Padding) + CGFloat(row) * CGFloat(tileHeight)

            for _ in 0..<numberOfImages {
                let texture = imageTextures[textureIndex]
                let aspect = Float(texture.width) / Float(texture.height)
                let width = UserSettings.TileSize * aspect

                let textureSize = CGSize(width: CGFloat(width), height: CGFloat(UserSettings.TileSize))
                let textureOrigin = CGPoint(x: origin.x + CGFloat(offset), y: origin.y + rowDelta)
                let textureInstance = Tile(size: textureSize, origin: textureOrigin)

                tiledTextures[textureIndex].tiles.append(textureInstance)

                offset += width + UserSettings.Padding

                textureIndex += 1
                textureIndex %= imageTextures.count
            }

            offset = UserSettings.Padding
        }

        shouldRetile = false
    }
}

// MARK: - Grid with Equal Shortest Sides

extension ImageTiler {
    internal func tileImagesAsGridWithEqualShortestSides() {
        tiledTextures = imageTextures.compactMap(TextureInstance.init)

        let tileSize = CGFloat(UserSettings.TileSize + UserSettings.Padding)
        let numberOfCols = Int(ceil((Float(UserSettings.OutputSize.width) + UserSettings.Padding) / Float(tileSize)))
        let numberOfRows = Int(ceil((Float(UserSettings.OutputSize.height) + UserSettings.Padding) / Float(tileSize)))
        let contentsSize = CGSize(width: CGFloat(UserSettings.Padding) + CGFloat(numberOfCols) * tileSize, height: CGFloat(UserSettings.Padding) + CGFloat(numberOfRows) * tileSize)

        var textureIndex = 0
        let origin = CGPoint(x: (UserSettings.OutputSize.width - contentsSize.width) / 2.0,
                y: (UserSettings.OutputSize.height - contentsSize.height) / 2.0)

        for col in 0..<numberOfCols {
            for row in 0..<numberOfRows {
                let texture = imageTextures[textureIndex]
                let textureSize = CGSize(aspectRatio: CGSize(width: texture.width, height: texture.height), withShortestSide: CGFloat(UserSettings.TileSize))
                let textureDelta = CGSize(width: (textureSize.width - CGFloat(UserSettings.TileSize)) / 2.0, height: (textureSize.height - CGFloat(UserSettings.TileSize)) / 2.0)
                let textureOrigin = CGPoint(x: origin.x + CGFloat(UserSettings.Padding) + CGFloat(col) * tileSize - textureDelta.width,
                        y: origin.y + CGFloat(UserSettings.Padding) + CGFloat(row) * tileSize - textureDelta.height)
                let textureInstance = Tile(size: textureSize, origin: textureOrigin)
                tiledTextures[textureIndex].tiles.append(textureInstance)

                textureIndex += 1
                textureIndex %= imageTextures.count
            }
        }

        shouldRetile = false
    }
}

// MARK: - Interlocking Grid with Equal Shortest Sides

extension ImageTiler {
    internal func tileImagesAsInterlockingHexagonalGrid() {
        tiledTextures = imageTextures.compactMap(TextureInstance.init)

        let apothemFactor = CGFloat(sqrt(3) / 2)
        let apothem = CGFloat(UserSettings.TileSize) * apothemFactor

        let imageSize = CGSize(width: apothem * apothemFactor, height: apothem)
        let tileSize = CGSize(width: imageSize.width + CGFloat(UserSettings.Padding), height: imageSize.height + CGFloat(UserSettings.Padding))
        let numberOfCols = Int(ceil((Float(UserSettings.OutputSize.width) + UserSettings.Padding) / Float(tileSize.width)))
        let numberOfRows = Int(ceil((Float(UserSettings.OutputSize.height) + UserSettings.Padding) / Float(tileSize.height)))
        let contentsSize = CGSize(width: CGFloat(UserSettings.Padding) + CGFloat(numberOfCols) * tileSize.width,
                height: CGFloat(UserSettings.Padding) + CGFloat(numberOfRows) * tileSize.height)

        var textureIndex = 0
        var shouldOffsetColumn = false
        let interlockingOffset = CGFloat(0.5 * tileSize.height)
        let origin = CGPoint(x: (UserSettings.OutputSize.width - contentsSize.width) / 2.0,
                y: (UserSettings.OutputSize.height - contentsSize.height) / 2.0)

        for col in 0..<numberOfCols {
            let adjustedNumberOfRows = numberOfRows + (shouldOffsetColumn ? 1 : 0)
            let adjustedInterlockingOffset = shouldOffsetColumn ? interlockingOffset : 0

            for row in 0..<adjustedNumberOfRows {
                let texture = imageTextures[textureIndex]
                let textureSize = CGSize(aspectRatio: CGSize(width: texture.width, height: texture.height), withShortestSide: CGFloat(UserSettings.TileSize))
                let textureDelta = CGSize(width: (textureSize.width - imageSize.width) / 2.0, height: (textureSize.height - imageSize.height) / 2.0)
                let textureOrigin = CGPoint(x: origin.x + CGFloat(UserSettings.Padding) + CGFloat(col) * tileSize.width - textureDelta.width,
                        y: origin.y + CGFloat(UserSettings.Padding) + CGFloat(row) * tileSize.height - textureDelta.height - adjustedInterlockingOffset)
                let textureInstance = Tile(size: textureSize, origin: textureOrigin)
                tiledTextures[textureIndex].tiles.append(textureInstance)

                textureIndex += 1
                textureIndex %= imageTextures.count
            }

            shouldOffsetColumn = !shouldOffsetColumn
        }

        shouldRetile = false
    }
}
