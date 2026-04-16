//
//  SettingsWindow.swift
//  AltTab — Windows-style Window Switcher for macOS
//
//  Settings window with General tab for permission management.
//  Allows users to check permission status and request permissions.
//
//  Author:  Sergio Farfan <sergio.farfan@gmail.com>
//  Version: 1.2.0
//  Date:    2026-04-06
//  License: MIT
//

import Cocoa
import ScreenCaptureKit
import ServiceManagement

final class SettingsWindowController: NSWindowController {

    private var permissionStatusTimer: Timer?
    private var accessibilityStatusLabel: NSTextField?
    private var accessibilityButton: NSButton?
    private var screenRecordingStatusLabel: NSTextField?
    private var screenRecordingButton: NSButton?

    convenience init() {
        // Layout (y from bottom, AppKit coordinates):
        //   360 total height
        //   [20] bottom margin
        //   [100] screen recording box   y=20
        //   [20] gap
        //   [100] accessibility box      y=140
        //   [10] gap
        //   [20] description label       y=250
        //   [6]  gap
        //   [24] "Permissions" title     y=276
        //   [14] gap
        //   [22] launch at login         y=314
        //   [24] top margin
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AltTab Settings"
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
        setupUI()
    }

    private func setupUI() {
        guard let window = window else { return }

        guard let existingContentView = window.contentView else { return }
        let contentView = NSView(frame: existingContentView.bounds)
        contentView.autoresizingMask = [.width, .height]

        // Launch at Login checkbox  (y=314, h=22)
        let launchAtLoginCheckbox = NSButton(
            checkboxWithTitle: "Launch at Login",
            target: self,
            action: #selector(toggleLaunchAtLogin(_:))
        )
        launchAtLoginCheckbox.frame = NSRect(x: 20, y: 314, width: 200, height: 22)
        if #available(macOS 13.0, *) {
            launchAtLoginCheckbox.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
        contentView.addSubview(launchAtLoginCheckbox)

        // "Permissions" title  (y=276, h=24)
        let permissionsTitle = NSTextField(labelWithString: "Permissions")
        permissionsTitle.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        permissionsTitle.frame = NSRect(x: 20, y: 276, width: 480, height: 24)
        contentView.addSubview(permissionsTitle)

        // Description  (y=250, h=20)
        let descLabel = NSTextField(labelWithString: "AltTab requires the following permissions to function properly:")
        descLabel.font = NSFont.systemFont(ofSize: 12)
        descLabel.textColor = .secondaryLabelColor
        descLabel.frame = NSRect(x: 20, y: 250, width: 480, height: 20)
        contentView.addSubview(descLabel)

        // Accessibility box  (y=140, h=100)
        let (accessibilityBox, accessibilityStatus, accessibilityBtn) = createPermissionBox(
            title: "Accessibility",
            description: "Required for global hotkey detection and window management",
            yPosition: 140,
            requestAction: #selector(requestAccessibilityPermission)
        )
        self.accessibilityStatusLabel = accessibilityStatus
        self.accessibilityButton = accessibilityBtn
        contentView.addSubview(accessibilityBox)

        // Screen Recording box  (y=20, h=100)
        let (screenRecordingBox, screenRecordingStatus, screenRecordingBtn) = createPermissionBox(
            title: "Screen Recording",
            description: "Must be added manually in System Settings (auto-request is unreliable)",
            yPosition: 20,
            requestAction: #selector(openScreenRecordingSettings)
        )
        self.screenRecordingStatusLabel = screenRecordingStatus
        self.screenRecordingButton = screenRecordingBtn
        contentView.addSubview(screenRecordingBox)

        window.contentView = contentView

        updatePermissionStatus()
        permissionStatusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updatePermissionStatus()
        }
    }

    // Box interior layout (box: 480w × 100h, coordinates relative to box bounds).
    // NSBox .primary has ~5px visual inset on all sides, so usable area is y=5..95.
    // Distribute 3 rows (20+18+18=56px) with equal top/bottom margins (~13px each):
    //   title:   x=14  y=62  w=300  h=20  → top at 82, 13px from visual border
    //   desc:    x=14  y=40  w=300  h=18
    //   status:  x=14  y=8   w=200  h=18  → bottom at 8, 13px from visual border
    //   button:  x=320 y=30  w=146  h=32  (right side, vertically centred in box)
    private func createPermissionBox(
        title: String, description: String,
        yPosition: CGFloat, requestAction: Selector
    ) -> (NSView, NSTextField, NSButton) { // swiftlint:disable:this large_tuple
        let box = NSBox(frame: NSRect(x: 20, y: yPosition, width: 480, height: 100))
        box.titlePosition = .noTitle
        box.boxType = .primary

        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.frame = NSRect(x: 14, y: 62, width: 300, height: 20)
        box.addSubview(titleLabel)

        let descLabel = NSTextField(labelWithString: description)
        descLabel.font = NSFont.systemFont(ofSize: 11)
        descLabel.textColor = .secondaryLabelColor
        descLabel.lineBreakMode = .byWordWrapping
        descLabel.frame = NSRect(x: 14, y: 40, width: 300, height: 18)
        box.addSubview(descLabel)

        let statusLabel = NSTextField(labelWithString: "Checking...")
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.frame = NSRect(x: 14, y: 8, width: 200, height: 18)
        box.addSubview(statusLabel)

        let requestButton = NSButton(title: "Grant Permission", target: self, action: requestAction)
        requestButton.bezelStyle = .rounded
        requestButton.frame = NSRect(x: 320, y: 30, width: 146, height: 32)
        box.addSubview(requestButton)

        return (box, statusLabel, requestButton)
    }

    @objc private func updatePermissionStatus() {
        if let statusLabel = accessibilityStatusLabel, let button = accessibilityButton {
            let isGranted = checkAccessibilityPermission()
            statusLabel.stringValue = isGranted ? "✓ Granted" : "✗ Not Granted"
            statusLabel.textColor = isGranted ? .systemGreen : .systemRed
            // Always show so users can re-request during dev (TCC gets confused on rebuilds)
            button.title = isGranted ? "Re-request" : "Grant Permission"
        }

        if let statusLabel = screenRecordingStatusLabel, let button = screenRecordingButton {
            let isGranted = checkScreenRecordingPermission()
            statusLabel.stringValue = isGranted ? "✓ Granted" : "✗ Not Granted"
            statusLabel.textColor = isGranted ? .systemGreen : .systemRed
            button.title = "Open System Settings"
        }
    }

    // MARK: - Accessibility Permission

    @objc private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    @objc private func requestAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
            Please grant Accessibility permission in:\n\
            System Settings → Privacy & Security → Accessibility\n\
            Then click 'Add' (+) and select AltTab.app
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let urlString = "x-apple.systempreferences:"
                + "com.apple.preference.security?Privacy_Accessibility"
            guard let url = URL(string: urlString) else { return }
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Screen Recording Permission

    @objc private func checkScreenRecordingPermission() -> Bool {
        // Lightweight check — CGWindowListCopyWindowInfo requires Screen Recording;
        // if it returns nil or an empty list while other apps are running, permission is denied.
        // We use a simple heuristic: if the list returns at least one entry we're likely granted.
        let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]]
        return !(windowList?.isEmpty ?? true)
    }

    @objc private func openScreenRecordingSettings() {
        let urlString = "x-apple.systempreferences:"
            + "com.apple.preference.security?Privacy_ScreenCapture"
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Launch at Login

    @objc private func toggleLaunchAtLogin(_ sender: NSButton) {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    sender.state = .off
                } else {
                    try SMAppService.mainApp.register()
                    sender.state = .on
                }
            } catch {
                let alert = NSAlert()
                alert.messageText = "Failed to Update Launch at Login"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
        updatePermissionStatus()
    }

    deinit {
        permissionStatusTimer?.invalidate()
    }
}
