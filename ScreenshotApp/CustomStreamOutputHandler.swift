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
    private weak var captureWindow: NSWindow? // 添加对截图窗口的引用

    init(rect: NSRect, captureWindow: NSWindow?) {
        self.rect = rect
        self.captureWindow = captureWindow
        super.init()
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        print("Stream callback triggered with type: \(outputType)")
        
        // 先停止捕获，避免半透明窗口影响截图质量
        stream.stopCapture { error in
            if let error = error {
                print("Failed to stop capture: \(error)")
            } else {
                print("Stream stopped")
                
                // 在停止捕获后，隐藏截图窗口
                DispatchQueue.main.async { [weak self] in
                    self?.captureWindow?.orderOut(nil)
                    
                    // 然后处理图像
                    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                        print("No image buffer available")
                        return
                    }

                    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
                    let nsImage = NSImage(size: self?.rect.size ?? .zero)
                    nsImage.addRepresentation(NSCIImageRep(ciImage: ciImage))
                    
                    // 显示预览
                    self?.capturedImage = nsImage
                    self?.showPreview(image: nsImage)
                }
            }
        }
    }

    private func showPreview(image: NSImage) {
        let previewWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height + 40),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        previewWindow.title = "截图预览"
        previewWindow.level = .floating
        previewWindow.center()

        let imageView = NSImageView(frame: NSRect(x: 0, y: 40, width: image.size.width, height: image.size.height))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        previewWindow.contentView?.addSubview(imageView)

        let saveButton = NSButton(frame: NSRect(x: 10, y: 5, width: 80, height: 30))
        saveButton.title = "保存"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveImage)
        previewWindow.contentView?.addSubview(saveButton)

        let cancelButton = NSButton(frame: NSRect(x: 100, y: 5, width: 80, height: 30))
        cancelButton.title = "取消"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelPreview)
        previewWindow.contentView?.addSubview(cancelButton)

        self.previewWindow = previewWindow
        previewWindow.makeKeyAndOrderFront(nil)
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
                        
                        // 保存成功后关闭所有窗口
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
    
    private func closeAllWindows() {
        DispatchQueue.main.async { [weak self] in
            // 关闭预览窗口
            self?.previewWindow?.close()
            // 关闭截图窗口并退出应用
            self?.captureWindow?.close()
            NSApp.terminate(nil)
        }
    }
}
