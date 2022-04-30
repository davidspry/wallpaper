//
//  NSSizeExtensions.swift
//  Wallpaper
//
//  Created by David Spry on 9/4/22.
//

import Cocoa

extension NSSize: Comparable {
    public static func <(lhs: CGSize, rhs: CGSize) -> Bool {
        lhs.area < rhs.area
    }
}

extension NSSize {
    var area: CGFloat {
        width * height
    }
    
    var aspectRatio: CGFloat {
        height / width
    }
    
    var shortestDimension: CGFloat {
        min(height, width)
    }
    
    var longestDimension: CGFloat {
        max(height, width)
    }
    
    init(aspectRatio: NSSize, withWidth targetWidth: CGFloat) {
        self.init(
                width: targetWidth,
                height: targetWidth * aspectRatio.aspectRatio
        )
    }

    init(aspectRatio: NSSize, withHeight targetHeight: CGFloat) {
        self.init(
                width: targetHeight / aspectRatio.aspectRatio,
                height: targetHeight
        )
    }

    init(aspectRatio: NSSize, withShortestSide shortestSide: CGFloat) {
        if aspectRatio.width <= aspectRatio.height {
            self.init(aspectRatio: aspectRatio, withWidth: shortestSide)
        } else {
            self.init(aspectRatio: aspectRatio, withHeight: shortestSide)
        }
    }
    
    init(aspectRatio: NSSize, withLongestSide longestSide: CGFloat) {
        if aspectRatio.width >= aspectRatio.height {
            self.init(aspectRatio: aspectRatio, withWidth: longestSide)
        } else {
            self.init(aspectRatio: aspectRatio, withHeight: longestSide)
        }
    }

    init(squareWithSize size: CGFloat) {
        self.init(width: size, height: size)
    }
}
