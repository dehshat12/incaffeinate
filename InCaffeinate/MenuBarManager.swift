import SwiftUI
import AppKit
import Combine

class MenuBarManager: NSObject, ObservableObject {
    var statusItem: NSStatusItem?
    var controller: CaffeinateController
    private var cancellables = Set<AnyCancellable>()
    private var updateTooltipTimer: Timer?
    private var customTimerWindow: NSWindow?
    private var settingsWindow: NSWindow?
    
    init(controller: CaffeinateController) {
        self.controller = controller
        super.init()
        setupMenuBar()
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard statusItem?.button != nil else { return }
        
        // Set initial icon
        updateIcon()
        
        // Create menu
        let menu = NSMenu()
        
        // Status item
        let statusMenuItem = NSMenuItem()
        let statusView = NSHostingView(rootView: MenuBarStatusView(controller: controller))
        statusView.frame = NSRect(x: 0, y: 0, width: 200, height: 60)
        statusMenuItem.view = statusView
        menu.addItem(statusMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Toggle button
        let toggleItem = NSMenuItem(
            title: controller.isActive ? "Stop Caffeinate" : "Start Caffeinate",
            action: #selector(toggleCaffeinate),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Timer presets
        let timerMenu = NSMenu()
        
        let timer15 = NSMenuItem(title: "15 Minutes", action: #selector(setTimer15), keyEquivalent: "")
        timer15.target = self
        timerMenu.addItem(timer15)
        
        let timer30 = NSMenuItem(title: "30 Minutes", action: #selector(setTimer30), keyEquivalent: "")
        timer30.target = self
        timerMenu.addItem(timer30)
        
        let timer60 = NSMenuItem(title: "1 Hour", action: #selector(setTimer60), keyEquivalent: "")
        timer60.target = self
        timerMenu.addItem(timer60)
        
        let timerCustom = NSMenuItem(title: "Custom Timer...", action: #selector(showCustomTimer), keyEquivalent: "")
        timerCustom.target = self
        timerMenu.addItem(timerCustom)
        
        let timerMenuItem = NSMenuItem(title: "Set Timer", action: nil, keyEquivalent: "")
        timerMenuItem.submenu = timerMenu
        menu.addItem(timerMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings",
            action: #selector(showSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit InCaffeinate",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
        
        // Update icon and tooltip when controller changes
        controller.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Update tooltip when remaining time changes
        controller.$remainingTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateIcon()
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        // Start timer to update tooltip and menu periodically
        updateTooltipTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateIcon()
            // Force menu update to refresh status view
            if let menu = self?.statusItem?.menu {
                menu.items.forEach { item in
                    if let hostingView = item.view as? NSHostingView<MenuBarStatusView> {
                        hostingView.needsLayout = true
                    }
                }
            }
        }
    }
    
    func updateIcon() {
        guard let button = statusItem?.button else { return }
        
        let iconName = controller.isActive ? "bolt.fill" : "bolt.slash.fill"
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        image?.isTemplate = true
        button.image = image
        
        // Set tooltip with remaining time
        if controller.isActive && controller.remainingTime > 0 {
            button.toolTip = "InCaffeinate - Active\nRemaining: \(controller.formattedRemainingTime)"
        } else if controller.isActive {
            button.toolTip = "InCaffeinate - Active\nNo timer set"
        } else {
            button.toolTip = "InCaffeinate - Inactive"
        }
    }
    
    func updateMenu() {
        guard let menu = statusItem?.menu else { return }
        
        // Update toggle item title
        if let toggleItem = menu.items.first(where: { $0.action == #selector(toggleCaffeinate) }) {
            toggleItem.title = controller.isActive ? "Stop Caffeinate" : "Start Caffeinate"
        }
    }
    
    @objc func toggleCaffeinate() {
        if controller.isActive {
            controller.stop()
        } else {
            controller.start()
        }
        updateIcon()
        updateMenu()
    }
    
    @objc func setTimer15() {
        guard controller.isActive else { return }
        controller.startTimer(minutes: 15)
        updateIcon()
    }
    
    @objc func setTimer30() {
        guard controller.isActive else { return }
        controller.startTimer(minutes: 30)
        updateIcon()
    }
    
    @objc func setTimer60() {
        guard controller.isActive else { return }
        controller.startTimer(minutes: 60)
        updateIcon()
    }
    
    @objc func showCustomTimer() {
        // Close existing window if open
        customTimerWindow?.close()
        
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Create and show custom timer window
        customTimerWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        customTimerWindow?.title = "Custom Timer"
        customTimerWindow?.center()
        
        let customTimerView = CustomTimerView(controller: controller)
            .frame(width: 300, height: 380)
        
        let hostingView = NSHostingView(rootView: customTimerView)
        customTimerWindow?.contentView = hostingView
        
        customTimerWindow?.makeKeyAndOrderFront(nil)
        
        // When window closes, return to menu bar only mode
        customTimerWindow?.isReleasedWhenClosed = false
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: customTimerWindow, queue: .main) { [weak self] _ in
            self?.customTimerWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    @objc func showSettings() {
        // Close existing window if open
        settingsWindow?.close()
        
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Create and show settings window
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow?.title = "Settings"
        settingsWindow?.center()
        
        let settingsView = SettingsView(controller: controller)
            .frame(minWidth: 420, minHeight: 480)
        
        let hostingView = NSHostingView(rootView: settingsView)
        settingsWindow?.contentView = hostingView
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        
        // When window closes, return to menu bar only mode
        settingsWindow?.isReleasedWhenClosed = false
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: settingsWindow, queue: .main) { [weak self] _ in
            self?.settingsWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

struct MenuBarStatusView: View {
    @ObservedObject var controller: CaffeinateController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: controller.isActive ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundStyle(controller.isActive ? .green : .gray)
                Text(controller.isActive ? "Active" : "Inactive")
                    .font(.headline)
                Spacer()
            }
            
            if controller.isActive && controller.remainingTime > 0 {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text("Remaining: \(controller.formattedRemainingTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 200)
    }
}
