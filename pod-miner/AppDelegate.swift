//
//  AppDelegate.swift
//  pod-outdated
//
//  Created by Lukas Würzburger on 6/30/20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    enum State {
        case running
        case idle(CheckResult?)
    }

    struct CheckResult {
        var date: Date
        var updates: [DependencyUpdate]
    }

    // MARK: - Variables

    var windowController: NSWindowController!
    var statusBarItem: NSStatusItem!
    var state = State.idle(nil) {
        didSet {
            updateStatusMenuItem()
            updateStatusBarItemMenu()
        }
    }
    var timer: Timer?

    // MARK: - Application Delegate

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupWindowController()
        setupStatusBarItem()
        runScript()
        subscribeNotifications()
    }

    func setupWindowController() {
        windowController = NSWindowController(window: setupWindow())
    }

    func setupWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.title = "📦 Pod Miner Preferences"
        window.contentView = NSHostingView(rootView: SettingsView())
        return window
    }

    func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.title = "📦"
        setupStatusBarItemMenu()
    }

    func setupStatusBarItemMenu() {
        let menu = NSMenu(title: "")
        menu.addItem(statusMenuItem())
        menu.addItem(withTitle: "Check now", action: #selector(runScript), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Preferences ...", action: #selector(openWindow), keyEquivalent: ",")
        statusBarItem.menu = menu
    }

    func statusMenuItemTitle() -> String {
        let title: String
        if UserDefaults.standard.string(forKey: UserDefaultsKey.projectPath.rawValue) != nil {
            switch state {
            case .running:
                title = "Checking..."
            case .idle(let result):
                if let lastResult = result {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .short
                    dateFormatter.timeStyle = .short
                    let dateString = dateFormatter.string(from: lastResult.date)
                    title = "Last checked: \(dateString)"
                } else {
                    title = "Not yet checked"
                }
            }
        } else {
            title = "Not configured."
        }
        return title
    }

    func statusMenuItem() -> NSMenuItem {
        let title = statusMenuItemTitle()
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.tag = 11
        return item
    }

    func updateStatusMenuItem() {
        statusBarItem.menu?.item(withTag: 11)?.title = statusMenuItemTitle()
    }

    func updateStatusBarItemMenu() {
        guard let menu = statusBarItem.menu else { return }
        if case let .idle(result) = state, let lastResult = result {
            cocoapodsMenuItem(for: menu, lastResult: lastResult)
        }
    }

    func cocoapodsMenuItem(for menu: NSMenu, lastResult: CheckResult) {
        let cocoapodsMenu = NSMenu()
        let updateCount = lastResult.updates.count
        lastResult.updates.forEach { update in
            cocoapodsMenu.addItem(withTitle: update.description, action: nil, keyEquivalent: "")
        }
        let title = "Cocoapods (\(updateCount))"
        var menuItem: NSMenuItem! = menu.item(withTag: 21)
        if menuItem == nil {
            menuItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            menuItem.tag = 21
            menu.insertItem(.separator(), at: 4)
            menu.insertItem(menuItem, at: 5)
        }
        menuItem.title = title
        menu.setSubmenu(cocoapodsMenu, for: menuItem)
    }

    func subscribeNotifications() {
        NotificationCenter.default.addObserver(forName: SettingsView.didUpdateProjectPathNotification, object: nil, queue: .main) { _ in
            self.runScript()
        }
        NotificationCenter.default.addObserver(forName: SettingsView.didUpdateIntervalNotification, object: nil, queue: .main) { _ in
            self.runScript()
        }
    }

    @IBAction func openWindow(_ sender: Any) {
        if let window = windowController.window, window.isVisible == false {
            window.makeKeyAndOrderFront(1)
        }
    }

    @objc func runScript() {
        guard let path = UserDefaults.standard.string(forKey: UserDefaultsKey.projectPath.rawValue) else {
            return
        }
        guard let interval = CheckInterval(rawValue: UserDefaults.standard.double(forKey: UserDefaultsKey.interval.rawValue)) else {
            return
        }
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
        timer = Timer.scheduledTimer(withTimeInterval: interval.rawValue, repeats: false, block: { _ in
            self.runScript()
        })
        state = .running
        let shell = Shell()
        let command = "cd \(path) ; bundle exec pod outdated --no-ansi"
        DispatchQueue.global(qos: .background).async {
            shell.execute(command) { string, _ in
                var updates: [DependencyUpdate] = []
                if let string = string {
                    let formatter = CocoapodsFormatter()
                    updates = try! formatter.results(from: string)
                }
                DispatchQueue.main.async {
                    self.state = .idle(.init(date: Date(), updates: updates))
                }
            }
        }
    }
}
