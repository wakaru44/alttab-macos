//
//  AppDelegate.swift
//  AltTab — Windows-style Window Switcher for macOS
//
//  Application lifecycle and DI composition root. Creates all services via
//  constructor injection and wires them together. Delegates hotkey events to
//  SwitcherViewModel which coordinates business logic. No business logic here.
//
//  Author:  Sergio Farfan <sergio.farfan@gmail.com>
//  Version: 2.0.0
//  Date:    2026-04-06
//  License: MIT
//

import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, HotkeyDelegate {

    // MARK: - Services (created once, injected via constructors)

    private var accessibilityService: AccessibilityService!
    private var mruTracker: MRUTracker!
    private var windowEnumerator: WindowEnumerationService!
    private var thumbnailCache: ThumbnailRepository!
    private var windowCapture: WindowCapture!
    private var windowActivator: WindowActivator!
    private var windowTracker: WindowTracker!
    private var switcherViewModel: SwitcherViewModel!

    // MARK: - UI

    private var statusItem: NSStatusItem!
    private var preferencesMenu: PreferencesMenu!
    private var hotkeyManager: HotkeyManager!
    private var switcherPanel: SwitcherPanel!
    private var permissionManager: PermissionManager!

    // Force unwrap safe: All properties initialized in applicationDidFinishLaunching before any access

    // swiftlint:disable:next function_body_length
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("AltTab: applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        permissionManager = PermissionManager()

        // Compose dependency graph
        accessibilityService = AccessibilityService()
        mruTracker = MRUTracker()
        windowEnumerator = WindowEnumerationService(
            accessibilityService: accessibilityService,
            mruTracker: mruTracker
        )
        thumbnailCache = ThumbnailRepository()
        windowCapture = WindowCapture(thumbnailCache: thumbnailCache)
        windowActivator = WindowActivator(accessibilityService: accessibilityService)
        windowTracker = WindowTracker(
            accessibilityService: accessibilityService,
            mruTracker: mruTracker
        )
        windowTracker.startTracking()

        switcherPanel = SwitcherPanel()
        switcherViewModel = SwitcherViewModel(
            windowEnumerator: windowEnumerator,
            thumbnailCapture: windowCapture,
            windowActivator: windowActivator,
            mruTracker: mruTracker
        )

        // Bind ViewModel to View
        switcherViewModel.onUpdate = { [weak self] in
            guard let self = self else { return }
            if self.switcherViewModel.isActive {
                self.switcherPanel.show(
                    windows: self.switcherViewModel.windows,
                    selectedIndex: self.switcherViewModel.selectedIndex
                )
            } else {
                self.switcherPanel.dismiss()
            }
        }

        hotkeyManager = HotkeyManager()
        hotkeyManager.delegate = self

        if AXIsProcessTrusted() {
            hotkeyManager.start()
            NSLog("AltTab: Accessibility already granted, hotkey active")
        } else {
            NSLog("AltTab: Accessibility not yet trusted, will recheck before prompting")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else { return }
                if AXIsProcessTrusted() {
                    NSLog("AltTab: Accessibility granted after brief wait, hotkey active")
                    self.hotkeyManager.start()
                } else {
                    NSLog("AltTab: Accessibility still not trusted, prompting user")
                    self.permissionManager.ensureAccessibility()
                    NotificationCenter.default.addObserver(
                        forName: .accessibilityGranted, object: nil, queue: .main
                    ) { [weak self] _ in
                        NSLog("AltTab: Accessibility granted, starting hotkey manager")
                        self?.hotkeyManager.start()
                    }
                }
            }
        }
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let img = NSImage(systemSymbolName: "rectangle.on.rectangle",
                                  accessibilityDescription: "AltTab") {
                img.isTemplate = true
                button.image = img
            } else {
                button.title = "⌥⇥"
            }
        }
        preferencesMenu = PreferencesMenu()
        statusItem.menu = preferencesMenu.menu
        NSLog("AltTab: Status item installed")
    }

    // MARK: - HotkeyDelegate (delegates to ViewModel)

    func hotkeyDidActivate() {
        switcherViewModel.activate()
    }

    func hotkeyDidCycleNext() {
        switcherViewModel.cycleNext()
    }

    func hotkeyDidCyclePrevious() {
        switcherViewModel.cyclePrevious()
    }

    func hotkeyDidConfirm() {
        switcherViewModel.confirm()
    }

    func hotkeyDidCancel() {
        switcherViewModel.cancel()
    }
}
