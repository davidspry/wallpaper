//
//  Loading.swift
//  Wallpaper
//
//  Created by David Spry on 18/4/22.
//

import Cocoa

class LoadingAnimation: NSVisualEffectView {
    private var displayLink = DisplayTimer()
    private var animationTime: CGFloat = 0.0
    private let circle = NSView()
    private let circleSize: CGFloat = 32
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialiseViewContents()
    }
    
    fileprivate func initialiseViewContents() {
        self.wantsLayer = true
        self.blendingMode = .withinWindow
        self.material = .toolTip
        self.state = .followsWindowActiveState
        
        circle.translatesAutoresizingMaskIntoConstraints = false
        circle.wantsLayer = true
        circle.layer?.cornerRadius = circleSize / 2
        circle.layer?.masksToBounds = true
        
        addSubview(circle)
        
        NSLayoutConstraint.activate([
            circle.widthAnchor.constraint(equalToConstant: circleSize),
            circle.heightAnchor.constraint(equalToConstant: circleSize),
        ])
        
        initialiseAnimation()
    }
    
    fileprivate func initialiseAnimation() {
        displayLink?.callback = { [weak self] in
            if let circleSize = self?.circleSize,
               let animationTime = self?.animationTime {
                let alpha = 1.0 - 0.5 * (1.0 + cos(animationTime))
                let origin = NSPoint(x: 64 - circleSize * 0.5,
                                     y: 64 - circleSize * 0.5)
                
                NSAnimationContext.runAnimationGroup { _ in
                    self?.circle.frame.origin = origin
                    self?.circle.layer?.backgroundColor = NSColor
                        .controlAccentColor
                        .withAlphaComponent(alpha)
                        .cgColor
                }
                
                self?.animationTime += 0.1
                self?.animationTime.formTruncatingRemainder(dividingBy: 2.0 * CGFloat.pi)
            }
        }
    }
    
    func becomeVisibleAndAnimate() {
        animator().alphaValue = 1.0
        animationTime = 0.0
        displayLink?.start()
    }
    
    func stopAnimatingAndBecomeHidden() {
        NSAnimationContext.runAnimationGroup { _ in
            alphaValue = 0.0
        } completionHandler: {
            self.displayLink?.stop()
            self.circle.layer?.backgroundColor = .clear
        }
    }
}
