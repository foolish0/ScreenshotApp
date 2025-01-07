import Cocoa
import ScreenCaptureKit

class PermissionManager {
    static let shared = PermissionManager()
    
    private init() {}
    
    // 检查所有需要的权限
    func checkPermissions() async -> Bool {
        return await checkScreenCapturePermission()
    }
    
    // 检查屏幕录制权限
    private func checkScreenCapturePermission() async -> Bool {
        do {
            // 尝试获取可共享内容来检查权限
            _ = try await SCShareableContent.current
            return true
        } catch {
            print("Screen capture permission check failed: \(error)")
            // 显示权限请求对话框
            showPermissionAlert()
            return false
        }
    }
    
    private func requestScreenCapturePermission() async -> Bool {
        do {
            // 尝试获取可共享内容来触发系统权限请求
            _ = try await SCShareableContent.current
            return true
        } catch {
            print("Screen capture permission request failed: \(error)")
            showPermissionAlert()
            return false
        }
    }
    
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "需要屏幕录制权限"
            alert.informativeText = """
                为了实现截图功能，我们需要屏幕录制权限。
                
                请按照以下步骤操作：
                1. 点击"打开系统设置"
                2. 找到本应用
                3. 勾选复选框以授予权限
                
                授予权限后，请重新启动应用。
                """
            alert.alertStyle = .warning
            
            // 添加按钮
            alert.addButton(withTitle: "打开系统设置")
            alert.addButton(withTitle: "退出应用")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // 直接打开具体的设置页面
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                    NSWorkspace.shared.open(url)
                }
            } else {
                NSApp.terminate(nil)
            }
        }
    }
} 
