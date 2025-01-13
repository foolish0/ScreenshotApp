//
//  ScreenshotAppApp.swift
//  ScreenshotApp 应用入口
//
//  Created by 李振江 on 2025/1/6.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarManager: StatusBarManager?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Application did finish launching")
        
        // 确保应用保持运行
        NSApp.activate(ignoringOtherApps: true)
        
        // 先设置为 accessory 应用
        NSApp.setActivationPolicy(.accessory)
        
        // 创建状态栏管理器
        DispatchQueue.main.async { [weak self] in
            self?.statusBarManager = StatusBarManager()
            print("Status bar manager created")
        }
        
        // 关闭主窗口（如果有的话）
        NSApplication.shared.windows.forEach { window in
            window.close()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // 清理状态栏
        if let statusItem = statusBarManager?.statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        
        // 关闭所有窗口
        NSApplication.shared.windows.forEach { window in
            window.close()
        }
        
        // 清理状态栏管理器
        statusBarManager = nil
        
        // 打印日志
        print("Application will terminate")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
