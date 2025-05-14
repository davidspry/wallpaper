//
//  NSViewExtensions.swift
//  Wallpaper
//
//  Created by David Spry on 18/4/22.
//

import Cocoa

extension NSView {
    func centre(in view: NSView) {
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func pinToEdges(of view: NSView) {
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    weak var viewController: NSViewController? {
        var parentResponder: NSResponder? = nextResponder

        while parentResponder != nil {
            if let viewController = parentResponder as? NSViewController {
                return viewController
            }

            parentResponder = parentResponder?.nextResponder
        }

        return nil
    }
}
