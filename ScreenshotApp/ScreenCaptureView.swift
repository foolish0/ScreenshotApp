//
//  ScreenCaptureView.swift
//  ScreenshotApp 绘制截图区域和交互
//
//  Created by 李振江 on 2025/1/6.
//

import Cocoa
import ScreenCaptureKit

class ScreenCaptureView: NSView {
    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    private var currentStream: SCStream? // 保持对 stream 的强引用
    private var outputHandler: CustomStreamOutputHandler? // 保持对 handler 的强引用
    
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
        Task {
            await captureScreenWithScreenCaptureKit(rect: rect)
        }
    }
    
    private func captureScreenWithScreenCaptureKit(rect: NSRect) async {
        do {
            // 使用权限管理器检查权限
            guard await PermissionManager.shared.checkPermissions() else {
                print("Screen capture permission not granted")
                return
            }
            
            // 获取可共享内容
            let shareableContent = try await SCShareableContent.current
            
            // 获取当前屏幕
            guard let screen = NSScreen.main else {
                print("No main screen available")
                return
            }

            // 查找目标显示器
            guard let display = shareableContent.displays.first(where: { $0.displayID == screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID }) else {
                print("No matching display found")
                return
            }

            // 创建捕获配置
            let config = SCStreamConfiguration()
            config.width = Int(rect.width)
            config.height = Int(rect.height)
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1) // 设置最小帧间隔为1秒

            // 限制捕获区域
            let safeRect = rect.intersection(screen.frame)
            config.sourceRect = CGRect(
                x: safeRect.origin.x,
                y: screen.frame.height - safeRect.origin.y - safeRect.height,
                width: safeRect.width,
                height: safeRect.height
            )
            
            // 创建内容过滤器
            let contentFilter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])

            // 停止现有的流（如果有）
            if let currentStream = self.currentStream {
                try? await currentStream.stopCapture()
                self.currentStream = nil
            }

            // 创建新的流
            let stream = SCStream(filter: contentFilter, configuration: config, delegate: nil)
            self.currentStream = stream // 保持强引用
            
            // 创建并保存输出处理器
            let handler = CustomStreamOutputHandler(rect: rect)
            self.outputHandler = handler // 保持强引用
            
            // 添加输出处理器
            print("Adding stream output")
            try stream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: .main)
            
            // 开始捕获
            print("Starting stream capture...")
            try await stream.startCapture()
            print("Stream started successfully")
            
        } catch {
            print("Failed to capture screen: \(error.localizedDescription)")
        }
    }

    private func showPreview(image: NSImage, rect: NSRect) {
        let previewWindow = PreviewWindow(image: image, rect: rect)
        previewWindow.makeKeyAndOrderFront(nil)
    }
}
