//
//  ScreenshotAppApp.swift
//  ScreenshotApp 应用入口
//
//  Created by 李振江 on 2025/1/6.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: ScreenCaptureWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        addMenu()
        
        // 检查权限并启动应用
        Task {
            if await PermissionManager.shared.checkPermissions() {
                DispatchQueue.main.async {
                    self.startCapture()
                }
            }
        }
    }
    
    func addMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu()
        let quitMenuItem = NSMenuItem(title: "Quit ScreenshotApp", action: #selector(NSApp.terminate), keyEquivalent: "q")
        appMenu.addItem(quitMenuItem)
        appMenuItem.submenu = appMenu

        NSApp.mainMenu = mainMenu
    }
    
    func startCapture() {
        DispatchQueue.main.async {
            print("Starting Screen Capture on Main Thread: \(Thread.isMainThread)")
            self.window = ScreenCaptureWindow()
            self.window?.makeKeyAndOrderFront(nil)
            print("Window should now be visible")
        }
    }
}
