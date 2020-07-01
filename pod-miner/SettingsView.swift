//
//  SettingsView.swift
//  pod-outdated
//
//  Created by Lukas Würzburger on 6/30/20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import SwiftUI
import Combine
import AppKit


enum UserDefaultsKey: String {
    case projectPath = "projectPath"
    case interval = "interval"
}

enum CheckInterval: TimeInterval, CaseIterable, CustomStringConvertible {
    case hourly = 3600
    case daily = 86400
    case weekly = 604800

    var description: String {
        switch self {
        case .daily:
            return "Daily"
        case .hourly:
            return "Hourly"
        case .weekly:
            return "Weekly"
        }
    }
}

struct SettingsView: View {

    static let didUpdateProjectPathNotification = Notification.Name("didUpdateProjectPathNotification")
    static let didUpdateIntervalNotification = Notification.Name("didUpdateIntervalNotification")

    @State var projectPath: String = UserDefaults.standard.string(forKey: UserDefaultsKey.projectPath.rawValue) ?? "" {
        didSet {
            UserDefaults.standard.set(projectPath, forKey: UserDefaultsKey.projectPath.rawValue)
            NotificationCenter.default.post(name: SettingsView.didUpdateProjectPathNotification, object: nil)
        }
    }
    @State var interval = CheckInterval(rawValue: UserDefaults.standard.double(forKey: UserDefaultsKey.interval.rawValue)) ?? .hourly {
        didSet {
            UserDefaults.standard.set(interval.rawValue, forKey: UserDefaultsKey.interval.rawValue)
            NotificationCenter.default.post(name: SettingsView.didUpdateIntervalNotification, object: nil)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            GroupBox(label: Text("Pod Miner checks for updates and notifies you in the status bar.")) {
                VStack(alignment: .leading) {
                    HStack() {
                        Text("Location: ")
                        Text(projectPath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                        Button(action: {
                            self.showOpenPanel()
                        }, label: {
                            Text("Change...")
                        })
                    }
                    HStack(spacing: 0) {
                        Text("Interval: ")
                        MenuButton(label: Text(interval.description)) {
                            Button(action: {
                                self.interval = .hourly
                            }, label: {
                                Text(CheckInterval.hourly.description)
                            })
                            Button(action: {
                                self.interval = .daily
                            }, label: {
                                Text(CheckInterval.daily.description)
                            })
                            Button(action: {
                                self.interval = .weekly
                            }, label: {
                                Text(CheckInterval.weekly.description)
                            })
                        }
                        .frame(width: 100)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .frame(width: 500)
    }

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        if panel.runModal() == .OK {
            projectPath = panel.url!.path
        }
    }
}

struct ContentView_Previews: PreviewProvider {

    static var previews: some View {
        SettingsView()
    }
}
