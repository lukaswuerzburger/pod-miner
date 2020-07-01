//
//  CocoapodsFormatter.swift
//  pod-outdated
//
//  Created by Lukas Würzburger on 6/30/20.
//  Copyright © 2020 Lukas Würzburger. All rights reserved.
//

import Foundation

class CocoapodsFormatter {

    func results(from string: String) throws -> [DependencyUpdate] {
        let pattern = "^- ([A-Za-z]+) ([A-Za-z0-9.-]+) -> ([()A-Za-z0-9.-]+) \\(latest version ([A-Za-z0-9.-]+)\\)$"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return string.split(separator: "\n").map({ String($0) }).compactMap { line in
            if let match = regex?.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                let name = String(line[Range(match.range(at: 1), in: line)!])
                let current = String(line[Range(match.range(at: 2), in: line)!])
                let next = String(line[Range(match.range(at: 3), in: line)!])
                let latest = String(line[Range(match.range(at: 4), in: line)!])
                return .init(name: name, currentVersion: current, newerVersion: next, latestVersion: latest)
            } else {
                return nil
            }
        }
    }
}
