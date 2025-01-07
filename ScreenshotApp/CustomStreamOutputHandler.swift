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

    init(rect: NSRect) {
        self.rect = rect
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        print("Stream callback triggered with type: \(outputType)")
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("No image buffer available")
            return
        }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let nsImage = NSImage(size: rect.size)
        nsImage.addRepresentation(NSCIImageRep(ciImage: ciImage))

        DispatchQueue.main.async {
            // 保存捕获的图像到变量
            self.capturedImage = nsImage

            // 显示预览窗口
            self.showPreview(image: nsImage)
            
            // 停止流
            stream.stopCapture { error in
                if let error = error {
                    print("Failed to stop capture: \(error)")
                } else {
                    print("Stream stopped")
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
        previewWindow.center() // 窗口居中显示

        // 创建图片视图
        let imageView = NSImageView(frame: NSRect(x: 0, y: 40, width: image.size.width, height: image.size.height))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        previewWindow.contentView?.addSubview(imageView)

        // 创建保存按钮
        let saveButton = NSButton(frame: NSRect(x: 10, y: 5, width: 80, height: 30))
        saveButton.title = "保存"
        saveButton.target = self
        saveButton.action = #selector(saveImage)
        previewWindow.contentView?.addSubview(saveButton)

        // 创建取消按钮
        let cancelButton = NSButton(frame: NSRect(x: 100, y: 5, width: 80, height: 30))
        cancelButton.title = "取消"
        cancelButton.target = self
        cancelButton.action = #selector(cancelPreview)
        previewWindow.contentView?.addSubview(cancelButton)

        // 显示窗口
        previewWindow.makeKeyAndOrderFront(nil)
    }

    @objc private func saveImage() {
        guard let image = capturedImage else {
            print("No image captured to save")
            return
        }

        // 获取桌面路径
        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileName = "Screenshot-\(Date().timeIntervalSince1970).png"
        let fileURL = desktopPath.appendingPathComponent(fileName)

        // 创建保存面板
        let savePanel = NSSavePanel()
        savePanel.directoryURL = desktopPath
        savePanel.nameFieldStringValue = fileName
        savePanel.allowedFileTypes = ["png"]

        // 获取主窗口或当前窗口
        guard let window = NSApp.keyWindow else {
            print("No key window found for save panel.")
            return
        }

        // 显示保存面板
        DispatchQueue.main.async {
            savePanel.beginSheetModal(for: window) { result in
                if result == .OK, let selectedURL = savePanel.url {
                    do {
                        // 保存为 PNG 文件
                        if let tiffData = image.tiffRepresentation,
                           let bitmapRep = NSBitmapImageRep(data: tiffData),
                           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                            try pngData.write(to: selectedURL)
                            print("Image saved to: \(selectedURL.path)")
                        }
                    } catch {
                        print("Failed to save image: \(error)")
                    }
                }
            }
        }
    }

    @objc private func cancelPreview() {
        // 关闭所有相关窗口
        NSApp.keyWindow?.close()
    }
}
