//
//  TextField.swift
//  Wallpaper
//
//  Created by David Spry on 29/4/22.
//

import Cocoa

class TextField: NSTextField {
    var onTextChange: ((String, TextField) -> Void)? = nil

    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        onTextChange?(stringValue, self)
    }
}
