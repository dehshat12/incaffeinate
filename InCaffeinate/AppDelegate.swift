import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    var controller: CaffeinateController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up the app to run in menu bar only
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize controller and menu bar manager
        controller = CaffeinateController()
        menuBarManager = MenuBarManager(controller: controller!)
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Allow termination when user quits
        return .terminateNow
    }
}
