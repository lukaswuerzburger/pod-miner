//
//  shell.swift
//  dependencycheck
//
//  Created by Lukas Würzburger on 10/29/19.
//  Copyright © 2019 Truffls GmbH. All rights reserved.
//

import Foundation

class Shell {

    func execute(_ command: String, completion: @escaping (String?, Int32) -> Void) {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["sh", "-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.waitForDataInBackgroundAndNotify()

        var data = Data()

        var dataObserver: Any!
        dataObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outHandle, queue: nil) { notification -> Void in
            let availableData = outHandle.availableData
            data.append(availableData)
            if availableData.count > 0 || task.isRunning {
                outHandle.waitForDataInBackgroundAndNotify()
            } else {
                NotificationCenter.default.removeObserver(dataObserver!)
            }
        }

        var terminationObserver: Any!
        terminationObserver = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: task, queue: nil) { notification -> Void in
            let string = String(data: data, encoding: .utf8)
            completion(string, task.terminationStatus)
            NotificationCenter.default.removeObserver(terminationObserver!)
        }

        task.launch()
        task.waitUntilExit()
    }
}
