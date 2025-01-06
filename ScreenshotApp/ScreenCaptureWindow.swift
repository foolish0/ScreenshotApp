//
//  ScreenCaptureWindow.swift
//  ScreenshotApp 管理截图窗口
//
//  Created by 李振江 on 2025/1/6.
//

import Cocoa

class ScreenCaptureWindow: NSWindow {
    init() {
        guard let mainScreen = NSScreen.main else {
            fatalError("Error: No screen available!")
        }
        super.init(contentRect: mainScreen.frame,
                   styleMask: .borderless,
                   backing: .buffered,
                   defer: false)
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = false
        self.contentView = ScreenCaptureView()
        print("ScreenCaptureWindow initialized with frame: \(mainScreen.frame)")
    }
    
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }
    
    override func close() {
        super.close()
        NSApp.terminate(nil) // 应用退出
    }
}
