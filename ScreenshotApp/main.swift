import Cocoa

// 全局持有 AppDelegate 的实例，确保在整个应用生命周期中不会被释放
let appDelegate = AppDelegate()

let app = NSApplication.shared
app.delegate = appDelegate

// 运行应用
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
