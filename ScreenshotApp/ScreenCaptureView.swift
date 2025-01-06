//
//  ScreenCaptureView.swift
//  ScreenshotApp 绘制截图区域和交互
//
//  Created by 李振江 on 2025/1/6.
//

import Cocoa

class ScreenCaptureView: NSView {
    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    
    override init(frame: NSRect) {
            super.init(frame: frame)
            print("Initializing ScreenCaptureView")
            self.wantsLayer = true
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

    override func mouseDown(with event: NSEvent) {
        // 记录起始点
        startPoint = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPoint = startPoint else { return }
        // 计算拖拽框
        let currentPoint = convert(event.locationInWindow, from: nil)
        currentRect = NSRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect else { return }
        captureScreen(rect: rect)
        currentRect = nil
        startPoint = nil
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor(white: 0, alpha: 0.3).setFill()
        bounds.fill()

        if let rect = currentRect {
            NSColor.white.setStroke()
            rect.frame(withWidth: 2)
        }
    }

    private func captureScreen(rect: NSRect) {
        guard let screen = NSScreen.main else { return }
        let flippedRect = CGRect(
            x: rect.origin.x,
            y: screen.frame.height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        guard let cgImage = CGWindowListCreateImage(flippedRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else { return }
        let image = NSImage(cgImage: cgImage, size: rect.size)
        showPreview(image: image, rect: rect)
    }

    private func showPreview(image: NSImage, rect: NSRect) {
        let previewWindow = PreviewWindow(image: image, rect: rect)
        previewWindow.makeKeyAndOrderFront(nil)
    }
}
