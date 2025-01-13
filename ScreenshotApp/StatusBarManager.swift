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
        // 使用固定长度确保图标显示
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("init status bar")
        // 确保按钮存在并设置
        if let button = statusItem.button {
            button.title = "✂️"
            button.toolTip = "截图工具"
            print("Button title set to scissors emoji")
        } else {
            print("Failed to get status item button")
        }
        
        // 设置菜单
        let menu = NSMenu()
        menu.addItem(withTitle: "截图", action: #selector(startCapture), keyEquivalent: "c")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q")
        
        // 设置目标
        menu.items.forEach { item in
            item.target = self
        }
        
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
