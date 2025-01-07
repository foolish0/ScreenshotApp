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
        checkAndRequestPermission()
        print("Application Did Finish Launching")
        NSApp.setActivationPolicy(.regular) // 确保应用可以显示在 Dock 中
        addMenu()
        startCapture()
    }
    
    private func checkAndRequestPermission() {
            let isTrusted = AXIsProcessTrusted()
            print("Screen recording permission state: \(isTrusted)")

            if !isTrusted {
                let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
                AXIsProcessTrustedWithOptions(options)

                showPermissionAlert()
            } else {
                print("Screen recording permission granted.")
            }
        }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "屏幕录制权限未授予"
        alert.informativeText = "请前往系统设置 > 隐私与安全性 > 屏幕录制，勾选您的应用以启用屏幕录制权限。"
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "取消")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
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
