//
//  NSViewExtensions.swift
//  Wallpaper
//
//  Created by David Spry on 18/4/22.
//

import Cocoa

extension NSView {
    func centre(in view: NSView) {
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    func pinToEdges(of view: NSView) {
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    weak var viewController: NSViewController? {
        var parentResponder: NSResponder? = self.nextResponder
        
        while parentResponder != nil {
            if let viewController = parentResponder as? NSViewController {
                return viewController
            }
            
            parentResponder = parentResponder?.nextResponder
        }
        
        return nil
    }
}
