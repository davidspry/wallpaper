//
//  ComparableExtensions.swift
//  Wallpaper
//
//  Created by David Spry on 29/4/22.
//

import Foundation

extension Comparable {
    func bounded(between range: ClosedRange<Self>) -> Self {
        return min(range.upperBound, max(range.lowerBound, self))
    }
}
