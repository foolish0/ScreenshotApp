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
        previewWindow.center() // 窗口居中显示

        // 创建图片视图
        let imageView = NSImageView(frame: NSRect(x: 0, y: 40, width: image.size.width, height: image.size.height))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        previewWindow.contentView?.addSubview(imageView)

        // 创建保存按钮
        let saveButton = NSButton(frame: NSRect(x: 10, y: 5, width: 80, height: 30))
        saveButton.title = "保存"
        saveButton.bezelStyle = .rounded
        saveButton.target = self // 确保设置了正确的target
        saveButton.action = #selector(saveImage) // 设置action
        previewWindow.contentView?.addSubview(saveButton)

        // 创建取消按钮
        let cancelButton = NSButton(frame: NSRect(x: 100, y: 5, width: 80, height: 30))
        cancelButton.title = "取消"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self // 确保设置了正确的target
        cancelButton.action = #selector(cancelPreview) // 设置action
        previewWindow.contentView?.addSubview(cancelButton)

        // 保持对窗口的引用，防止被过早释放
        previewWindow.delegate = self
        
        // 显示窗口
        previewWindow.makeKeyAndOrderFront(nil)
    }

    @objc private func saveImage() {
        print("saveImage method called")
        guard let image = capturedImage else {
            print("No image to save")
            return
        }

        // 确保在主线程上执行
        DispatchQueue.main.async {
            // 创建保存面板
            let savePanel = NSSavePanel()
            savePanel.title = "保存截图"
            savePanel.nameFieldStringValue = "Screenshot-\(Int(Date().timeIntervalSince1970))"
            savePanel.allowedContentTypes = [.png]
            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            savePanel.directoryURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            
            // 显示保存面板
            guard let window = NSApp.windows.last else {
                print("No window available for sheet")
                return
            }
            
            savePanel.beginSheetModal(for: window) { [weak self] response in
                guard let self = self else { return }
                
                if response == .OK {
                    guard let url = savePanel.url else { return }
                    
                    // 保存为 PNG 文件
                    if let tiffData = image.tiffRepresentation,
                       let bitmapRep = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                        do {
                            try pngData.write(to: url)
                            print("Image saved successfully to: \(url.path)")
                            
                            // 关闭预览窗口
                            window.close()
                        } catch {
                            print("Failed to save image: \(error)")
                            
                            // 显示错误提示
                            let alert = NSAlert()
                            alert.messageText = "保存失败"
                            alert.informativeText = "无法保存截图：\(error.localizedDescription)"
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "确定")
                            alert.beginSheetModal(for: window, completionHandler: nil)
                        }
                    } else {
                        print("Failed to convert image to PNG")
                        
                        // 显示错误提示
                        let alert = NSAlert()
                        alert.messageText = "格式转换失败"
                        alert.informativeText = "无法将图像转换为PNG格式"
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "确定")
                        alert.beginSheetModal(for: window, completionHandler: nil)
                    }
                }
            }
        }
    }

    @objc private func cancelPreview() {
        // 关闭预览窗口
        NSApp.windows.last?.close()
    }
}

// 添加窗口代理协议
extension CustomStreamOutputHandler: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // 窗口关闭时的清理工作
        if let window = notification.object as? NSWindow {
            window.delegate = nil
        }
    }
}
