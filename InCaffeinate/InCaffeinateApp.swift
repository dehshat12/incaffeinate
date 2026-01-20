import SwiftUI
import AppKit

@main
struct InCaffeinateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var controller = CaffeinateController()
    
    var body: some Scene {
        // No WindowGroup - app runs in menu bar only
        Settings {
            EmptyView()
        }
        .commands {
            TimerCommands(controller: controller)
        }
    }
}
