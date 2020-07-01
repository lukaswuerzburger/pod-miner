//
//  DependencyUpdate.swift
//  pod-outdated
//
//  Created by Lukas Würzburger on 7/1/20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import Foundation

struct DependencyUpdate: CustomStringConvertible {
    var name: String
    var currentVersion: String
    var newerVersion: String
    var latestVersion: String

    var description: String {
        return "\(name) \(currentVersion) -> \(newerVersion) (latest \(latestVersion))"
    }
}
