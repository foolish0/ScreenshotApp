//
//  CustomStreamOutputHandler.swift
//  ScreenshotApp 自定义的输出类型
//
//  Created by 李振江 on 2025/1/6.
//

import Cocoa
import ScreenCaptureKit

class CustomStreamOutputHandler: NSObject, SCStreamOutput {
    private let rect: NSRect
    private var capturedImage: NSImage?
    private weak var previewWindow: NSWindow?
    private weak var captureWindow: NSWindow?
    private weak var stream: SCStream?
    private var isStreamStopped = false
    
    // 添加一个强引用来保持预览窗口存活
    private var retainedPreviewWindow: NSWindow?
    
    init(rect: NSRect, captureWindow: NSWindow?) {
        self.rect = rect
        self.captureWindow = captureWindow
        super.init()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        self.stream = stream
        print("Stream callback triggered with type: \(outputType)")
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("No image buffer available")
            return
        }

        // 在主线程上隐藏截图窗口
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let strongSelf = self, let captureWindow = strongSelf.captureWindow else { return }
            captureWindow.orderOut(nil)
            
            // 等待窗口完全隐藏后再进行截图
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let strongSelf = self else { return }
                
                // 创建 CIImage
                let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                
                // 创建正确尺寸的图像
                let nsImage = NSImage(size: strongSelf.rect.size)
                nsImage.addRepresentation(NSCIImageRep(ciImage: ciImage))
                
                // 显示预览
                strongSelf.capturedImage = nsImage
                strongSelf.showPreview(image: nsImage)
                
                // 停止捕获（仅在未停止的情况下调用）
                if !strongSelf.isStreamStopped {
                    strongSelf.isStreamStopped = true
                    stream.stopCapture { error in
                        if let error = error {
                            print("Failed to stop capture: \(error)")
                        }
                    }
                }
            }
        }
    }

    private func showPreview(image: NSImage) {
        if let existingWindow = self.previewWindow {
            existingWindow.orderOut(nil)
            existingWindow.close()
            self.previewWindow = nil
            self.retainedPreviewWindow = nil
        }
        // 创建无标题栏的窗口
        let previewWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height + 40),
            styleMask: [.borderless, .titled],
            backing: .buffered,
            defer: false
        )

        previewWindow.backgroundColor = .windowBackgroundColor
        previewWindow.level = .floating
        previewWindow.center()
        previewWindow.isMovableByWindowBackground = true
        previewWindow.titlebarAppearsTransparent = true
        previewWindow.titleVisibility = .hidden

        // 创建一个完全可拖动的自定义视图
        class DraggableContainerView: NSView {
            override var mouseDownCanMoveWindow: Bool { true }
            
            override func mouseDown(with event: NSEvent) {
                self.window?.performDrag(with: event)
            }
        }

        // 使用可拖动的视图作为主容器
        let containerView = DraggableContainerView(frame: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height + 40))
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // 图片视图
        let imageView = NSImageView(frame: NSRect(x: 0, y: 40, width: image.size.width, height: image.size.height))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        containerView.addSubview(imageView)

        // 保存按钮
        let saveButton = NSButton(frame: NSRect(x: 10, y: 5, width: 80, height: 30))
        saveButton.title = "save"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveImage)
        containerView.addSubview(saveButton)

        // 取消按钮
        let cancelButton = NSButton(frame: NSRect(x: 100, y: 5, width: 80, height: 30))
        cancelButton.title = "cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelPreview)
        containerView.addSubview(cancelButton)

        previewWindow.contentView = containerView
        self.previewWindow = previewWindow
        // 保持强引用
        self.retainedPreviewWindow = previewWindow
        previewWindow.makeKeyAndOrderFront(nil)
    }

    private func closeAllWindows() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            // 停止捕获流（如果还没有停止）
            if let stream = strongSelf.stream, !strongSelf.isStreamStopped {
                strongSelf.isStreamStopped = true
                stream.stopCapture { error in
                    if let error = error {
                        print("Failed to stop capture: \(error)")
                    }
                }
            }
            
            // 关闭预览窗口
            if let previewWindow = strongSelf.previewWindow {
                previewWindow.orderOut(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let strongSelf = self else { return }
                    previewWindow.close()
                    strongSelf.previewWindow = nil
                    // 清理强引用
                    strongSelf.retainedPreviewWindow = nil
                }
            }
            
            // 关闭截图窗口
            if let captureWindow = strongSelf.captureWindow {
                captureWindow.orderOut(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let strongSelf = self else { return }
                    captureWindow.close()
                    strongSelf.captureWindow = nil
                }
            }
            
            // 清理引用
            strongSelf.stream = nil
            strongSelf.capturedImage = nil
            strongSelf.isStreamStopped = false
        }
    }
    
    @objc private func saveImage() {
        guard let image = capturedImage else {
            print("No image captured to save")
            return
        }

        let savePanel = NSSavePanel()
        savePanel.title = "保存截图"
        savePanel.nameFieldStringValue = "Screenshot-\(Int(Date().timeIntervalSince1970))"
        savePanel.allowedContentTypes = [.png]
        savePanel.canCreateDirectories = true
        
        guard let window = previewWindow else { return }
        
        savePanel.beginSheetModal(for: window) { [weak self] response in
            if response == .OK, let url = savePanel.url {
                if let tiffData = image.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    do {
                        try pngData.write(to: url)
                        print("Image saved successfully to: \(url.path)")
                        
                        // 保存成功后只关闭相关窗口
                        DispatchQueue.main.async {
                            self?.closeAllWindows()
                        }
                    } catch {
                        print("Failed to save image: \(error)")
                    }
                }
            }
        }
    }

    @objc private func cancelPreview() {
        closeAllWindows()
    }
}
