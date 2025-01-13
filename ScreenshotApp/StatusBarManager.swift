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
        captureWindow?.close()
        captureWindow = ScreenCaptureWindow()
        captureWindow?.makeKeyAndOrderFront(nil)
    }
    
    @objc private func quit() {
        print("Quit triggered")
        NSApplication.shared.terminate(nil)
    }
} 
