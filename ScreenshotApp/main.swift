import Cocoa

// 创建应用和委托
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// 激活应用
app.activate(ignoringOtherApps: true)

// 运行应用
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv) 