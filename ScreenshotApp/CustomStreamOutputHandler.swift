//
//  CustomStreamOutputHandler.swift
//  ScreenshotApp 自定义的输出类型
//
//  Created by 李振江 on 2025/1/6.
//

import ScreenCaptureKit
import Cocoa

class CustomStreamOutputHandler: NSObject, SCStreamOutput {
    private let rect: NSRect
    private var capturedImage: NSImage?

    init(rect: NSRect) {
        self.rect = rect
        super.init()
        print("CustomStreamOutputHandler initialized")
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
        guard let image = capturedImage else { return }

        // 获取桌面路径
        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileName = "Screenshot-\(Date().timeIntervalSince1970).png"
        let fileURL = desktopPath.appendingPathComponent(fileName)

        // 保存为 PNG 文件
        if let tiffData = image.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: fileURL)
                print("Image saved to: \(fileURL.path)")
            } catch {
                print("Failed to save image: \(error)")
            }
        }

        // 关闭预览窗口
        NSApp.windows.last?.close()
    }

    @objc private func cancelPreview() {
        // 关闭预览窗口
        NSApp.windows.last?.close()
    }
}
