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
    private var currentStream: SCStream?
    private var outputHandler: CustomStreamOutputHandler?
    private var isDragging = false
    private var isResizing = false
    private var dragStartPoint: NSPoint?
    private var resizeHandle: ResizeHandle = .none
    private var isSelectionConfirmed = false
    
    // 定义调整大小的手柄区域
    private enum ResizeHandle {
        case none, topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
    }
    
    override var isOpaque: Bool {
        return false
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.wantsLayer = true
        self.layer?.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        if let rect = currentRect {
            // 检查是否点击了确认按钮
            let buttonWidth: CGFloat = 60
            let buttonHeight: CGFloat = 24
            let buttonRect = NSRect(
                x: rect.maxX - buttonWidth - 10,
                y: rect.maxY + 10,
                width: buttonWidth,
                height: buttonHeight
            )
            
            if NSPointInRect(point, buttonRect) {
                isSelectionConfirmed = true
                captureScreen(rect: rect)
                return
            }
            
            // 检查是否点击了调整大小的手柄
            resizeHandle = getResizeHandle(point: point, rect: rect)
            
            if resizeHandle != .none {
                isResizing = true
                dragStartPoint = point
                return
            }
            
            // 检查是否在选择区域内点击
            if NSPointInRect(point, rect) {
                // 更新光标为闭合手
                NSCursor.closedHand.set()
                isDragging = true
                dragStartPoint = point
                return
            }
            
            // 如果点击在选择区域外，开始新的选择
            if !isSelectionConfirmed {
                startPoint = point
                currentRect = nil
            }
        } else {
            startPoint = point
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        let currentPoint = convert(event.locationInWindow, from: nil)
        
        if isDragging {
            // 处理拖动
            guard let startPoint = dragStartPoint,
                  var rect = currentRect else { return }
            
            let dx = currentPoint.x - startPoint.x
            let dy = currentPoint.y - startPoint.y
            rect.origin.x += dx
            rect.origin.y += dy
            currentRect = rect
            dragStartPoint = currentPoint
            
        } else if isResizing {
            // 处理调整大小
            guard let rect = currentRect,
                  let startPoint = dragStartPoint else { return }
            
            let dx = currentPoint.x - startPoint.x
            let dy = currentPoint.y - startPoint.y
            var newRect = rect
            
            switch resizeHandle {
            case .topLeft:
                newRect.origin.x += dx
                newRect.size.width -= dx
                newRect.size.height += dy
            case .topRight:
                newRect.size.width += dx
                newRect.size.height += dy
            case .bottomLeft:
                newRect.origin.x += dx
                newRect.size.width -= dx
                newRect.origin.y += dy
                newRect.size.height -= dy
            case .bottomRight:
                newRect.size.width += dx
                newRect.origin.y += dy
                newRect.size.height -= dy
            case .top:
                newRect.size.height += dy
            case .bottom:
                newRect.origin.y += dy
                newRect.size.height -= dy
            case .left:
                newRect.origin.x += dx
                newRect.size.width -= dx
            case .right:
                newRect.size.width += dx
            case .none:
                break
            }
            
            // 确保宽度和高度不为负
            if newRect.size.width > 0 && newRect.size.height > 0 {
                currentRect = newRect
                dragStartPoint = currentPoint
            }
            
        } else {
            // 处理新的选择
            guard let startPoint = startPoint else { return }
            currentRect = NSRect(
                x: min(startPoint.x, currentPoint.x),
                y: min(startPoint.y, currentPoint.y),
                width: abs(currentPoint.x - startPoint.x),
                height: abs(currentPoint.y - startPoint.y)
            )
        }
        
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
        isResizing = false
        dragStartPoint = nil
        
        if !isSelectionConfirmed {
            // 只在第一次选择时重置起始点
            startPoint = nil
        }
        
        needsDisplay = true
        
        // 重置光标
        let point = convert(event.locationInWindow, from: nil)
        updateCursor(for: point)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if let rect = currentRect {
            NSGraphicsContext.current?.saveGraphicsState()
            
            // 绘制遮罩（添加渐变效果）
            let path = NSBezierPath(rect: bounds)
            path.append(NSBezierPath(rect: rect).reversed)
            
            // 创建渐变遮罩
            let gradient = NSGradient(colors: [
                NSColor(white: 0, alpha: 0.5),
                NSColor(white: 0, alpha: 0.3)
            ])
            gradient?.draw(in: path, angle: 45)
            
            // 绘制选择框边框（添加发光效果）
            let borderPath = NSBezierPath(rect: rect)
            borderPath.lineWidth = 2
            
            // 外发光效果
            NSColor.white.withAlphaComponent(0.3).setStroke()
            let glowPath = NSBezierPath(rect: rect.insetBy(dx: -2, dy: -2))
            glowPath.lineWidth = 4
            glowPath.stroke()
            
            // 主边框
            NSColor.white.setStroke()
            borderPath.stroke()
            
            // 如果已经有选择区域，绘制调整手柄和确认按钮
            if !isSelectionConfirmed {
                drawResizeHandles(rect: rect)
                drawConfirmButton(rect: rect)
                drawSizeIndicator(rect: rect)
            }
            
            NSGraphicsContext.current?.restoreGraphicsState()
        } else {
            // 初始状态的遮罩
            let gradient = NSGradient(colors: [
                NSColor(white: 0, alpha: 0.5),
                NSColor(white: 0, alpha: 0.3)
            ])
            gradient?.draw(in: bounds, angle: 45)
        }
    }
    
    private func drawResizeHandles(rect: NSRect) {
        let handleSize: CGFloat = 8
        let handles = [
            NSRect(x: rect.minX - handleSize/2, y: rect.minY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: rect.maxX - handleSize/2, y: rect.minY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: rect.minX - handleSize/2, y: rect.maxY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: rect.maxX - handleSize/2, y: rect.maxY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: rect.midX - handleSize/2, y: rect.minY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: rect.midX - handleSize/2, y: rect.maxY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: rect.minX - handleSize/2, y: rect.midY - handleSize/2, width: handleSize, height: handleSize),
            NSRect(x: rect.maxX - handleSize/2, y: rect.midY - handleSize/2, width: handleSize, height: handleSize)
        ]
        
        NSColor.white.setFill()
        handles.forEach { handle in
            NSBezierPath(rect: handle).fill()
        }
    }
    
    private func drawConfirmButton(rect: NSRect) {
        let buttonWidth: CGFloat = 60
        let buttonHeight: CGFloat = 24
        let buttonRect = NSRect(
            x: rect.maxX - buttonWidth - 10,
            y: rect.maxY + 10,
            width: buttonWidth,
            height: buttonHeight
        )
        
        // 绘制确认按钮
        NSColor.systemBlue.setFill()
        let buttonPath = NSBezierPath(roundedRect: buttonRect, xRadius: 4, yRadius: 4)
        buttonPath.fill()
        
        // 绘制按钮文字
        let text = "确认"
        let textAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 12)
        ]
        let textSize = text.size(withAttributes: textAttributes)
        let textPoint = NSPoint(
            x: buttonRect.midX - textSize.width/2,
            y: buttonRect.midY - textSize.height/2
        )
        text.draw(at: textPoint, withAttributes: textAttributes)
    }
    
    private func getResizeHandle(point: NSPoint, rect: NSRect) -> ResizeHandle {
        let handleSize: CGFloat = 8
        let hitArea: CGFloat = 8
        
        // 检查四个角
        if NSPointInRect(point, NSRect(x: rect.minX - hitArea, y: rect.minY - hitArea, width: handleSize, height: handleSize)) {
            return .bottomLeft
        }
        if NSPointInRect(point, NSRect(x: rect.maxX - hitArea, y: rect.minY - hitArea, width: handleSize, height: handleSize)) {
            return .bottomRight
        }
        if NSPointInRect(point, NSRect(x: rect.minX - hitArea, y: rect.maxY - hitArea, width: handleSize, height: handleSize)) {
            return .topLeft
        }
        if NSPointInRect(point, NSRect(x: rect.maxX - hitArea, y: rect.maxY - hitArea, width: handleSize, height: handleSize)) {
            return .topRight
        }
        
        // 检查边
        if NSPointInRect(point, NSRect(x: rect.midX - hitArea, y: rect.minY - hitArea, width: handleSize, height: handleSize)) {
            return .bottom
        }
        if NSPointInRect(point, NSRect(x: rect.midX - hitArea, y: rect.maxY - hitArea, width: handleSize, height: handleSize)) {
            return .top
        }
        if NSPointInRect(point, NSRect(x: rect.minX - hitArea, y: rect.midY - hitArea, width: handleSize, height: handleSize)) {
            return .left
        }
        if NSPointInRect(point, NSRect(x: rect.maxX - hitArea, y: rect.midY - hitArea, width: handleSize, height: handleSize)) {
            return .right
        }
        
        return .none
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
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

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

            // 先隐藏当前窗口
            await MainActor.run {
                self.window?.orderOut(nil)
            }
            
            // 等待窗口完全隐藏
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            
            // 停止现有的流（如果有）
            if let currentStream = self.currentStream {
                try? await currentStream.stopCapture()
                self.currentStream = nil
            }

            // 创建新的流
            let stream = SCStream(filter: contentFilter, configuration: config, delegate: nil)
            self.currentStream = stream
            
            // 创建并保存输出处理器
            let handler = CustomStreamOutputHandler(rect: rect, captureWindow: self.window)
            self.outputHandler = handler
            
            try stream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: .main)
            
            try await stream.startCapture()
            print("Stream started successfully")
            
        } catch {
            print("Failed to capture screen: \(error.localizedDescription)")
            // 如果出错，确保窗口重新显示
            await MainActor.run {
                self.window?.makeKeyAndOrderFront(nil)
            }
        }
    }

    private func showPreview(image: NSImage, rect: NSRect) {
        let previewWindow = PreviewWindow(image: image, rect: rect)
        previewWindow.makeKeyAndOrderFront(nil)
    }
    
    // 添加光标样式相关的方法
    private func updateCursor(for point: NSPoint) {
        if let rect = currentRect {
            // 获取手柄类型
            let handle = getResizeHandle(point: point, rect: rect)
            
            // 根据不同的手柄设置不同的光标
            let cursor: NSCursor = {
            switch handle {
            case .topLeft, .bottomRight:
                return NSCursor(image: NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right", accessibilityDescription: nil)!,
                              hotSpot: NSPoint(x: 8, y: 8)) // 使用系统默认光标
            case .topRight, .bottomLeft:
                return NSCursor(image: NSImage(systemSymbolName: "arrow.up.right.and.arrow.down.left", accessibilityDescription: nil)!,
                              hotSpot: NSPoint(x: 8, y: 8))
            case .top, .bottom:
                return NSCursor.resizeUpDown
            case .left, .right:
                return NSCursor.resizeLeftRight
            case .none:
                return NSPointInRect(point, rect) ? NSCursor.openHand : NSCursor.crosshair
            }
        }()
            
            if cursor != NSCursor.current {
                cursor.set()
            }
        } else {
            NSCursor.crosshair.set()
        }
    }
    
    // 修改绘制方法，添加尺寸提示
    private func drawSizeIndicator(rect: NSRect) {
        let text = String(format: "%.0f × %.0f", rect.width, rect.height)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 12),
            .backgroundColor: NSColor.black.withAlphaComponent(0.6)
        ]
        
        let textSize = text.size(withAttributes: textAttributes)
        let padding: CGFloat = 5
        
        // 计算文本位置（在选择框的左上角）
        let textRect = NSRect(
            x: rect.minX,
            y: rect.maxY + padding,
            width: textSize.width + padding * 2,
            height: textSize.height + padding * 2
        )
        
        // 绘制背景
        let bgPath = NSBezierPath(roundedRect: textRect, xRadius: 4, yRadius: 4)
        NSColor.black.withAlphaComponent(0.6).setFill()
        bgPath.fill()
        
        // 绘制文本
        let textPoint = NSPoint(
            x: textRect.minX + padding,
            y: textRect.minY + padding
        )
        text.draw(at: textPoint, withAttributes: textAttributes)
    }
    
    // 重写鼠标移动方法来更新光标
    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updateCursor(for: point)
    }
    
    
    
    
}
