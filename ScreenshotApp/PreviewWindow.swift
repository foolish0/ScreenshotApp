//
//  PreviewWindow.swift
//  ScreenshotApp 显示截图预览
//
//  Created by 李振江 on 2025/1/6.
//

import Cocoa

class PreviewWindow: NSWindow {
    init(image: NSImage, rect: NSRect) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: rect.width, height: rect.height),
                   styleMask: [.titled, .closable, .resizable],
                   backing: .buffered,
                   defer: false)
        self.center()
        self.contentView = PreviewView(image: image)
    }
}

class PreviewView: NSView {
    private let imageView = NSImageView()

    init(image: NSImage) {
        super.init(frame: NSRect.zero)
        self.imageView.image = image
        self.imageView.imageScaling = .scaleProportionallyUpOrDown
        self.imageView.frame = bounds
        self.imageView.autoresizingMask = [.width, .height]
        addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
