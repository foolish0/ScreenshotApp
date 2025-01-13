//
//  StatusBarManager.swift
//  ScreenshotApp 菜单栏应用
//
//  Created by 李振江 on 2025/1/7.
//


import Cocoa

class StatusBarManager {
    let statusItem: NSStatusItem
    private var captureWindow: ScreenCaptureWindow?
    
    // 添加一个强引用数组来保持窗口存活
    private var activeWindows: [NSWindow] = []
    
    init() {
        // 使用固定长度
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("init status bar")
        
        // 创建菜单
        let menu = NSMenu()
        let captureItem = NSMenuItem(title: "截图", action: #selector(startCapture), keyEquivalent: "c")
        captureItem.target = self
        menu.addItem(captureItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        // 设置按钮标题和图标
        if let button = statusItem.button {
            // 尝试使用系统符号图片
            if let image = NSImage(systemSymbolName: "scissors", accessibilityDescription: nil) {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = true
                button.image = image
            } else {
                // 如果无法加载系统符号，使用文本
                button.title = "截图"
            }
            
            button.toolTip = "截图工具"
            button.isEnabled = true
            print("Button configured")
        }
        
        // 最后设置菜单
        statusItem.menu = menu
        
        print("Status bar item initialized with menu")
    }
    
    @objc private func startCapture() {
        print("Start capture triggered")
        // 如果已经有截图窗口，先关闭它
        if let existingWindow = captureWindow {
            existingWindow.close()
            captureWindow = nil
            // 从活动窗口数组中移除
            activeWindows.removeAll { $0 === existingWindow }
        }
        
        // 创建新的截图窗口
        let newWindow = ScreenCaptureWindow()
        captureWindow = newWindow
        // 添加到活动窗口数组
        activeWindows.append(newWindow)
        newWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc private func quit() {
        print("Quit triggered")
        // 清理所有窗口
        activeWindows.forEach { $0.close() }
        activeWindows.removeAll()
        captureWindow = nil
        NSApplication.shared.terminate(nil)
    }
} 
