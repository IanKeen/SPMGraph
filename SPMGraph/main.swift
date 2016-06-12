//
//  main.swift
//  SPMGraph
//
//  Created by Ian Keen on 11/06/2016.
//  Copyright © 2016 Mustard. All rights reserved.
//

import Foundation

var indent = 0
var count = 0
var showCounts = false

func package(url: String) -> String {
    let parts = url
        .replacingOccurrences(of: "Package.swift", with: "")
        .components(separatedBy: "github.com/")
        .last!
        .components(separatedBy: "/")
        .map { $0.replacingOccurrences(of: ".git", with: "") }
        .filter { !$0.isEmpty }
    
    if (parts.count > 2) {
        return "https://raw.githubusercontent.com/" + parts[0] + "/" + parts[1] + "/" + parts[2] + "/Package.swift"
    } else {
        return "https://raw.githubusercontent.com/" + parts[0] + "/" + parts[1] + "/master/Package.swift"
    }
}
func get(url: String) -> String {
    let group = dispatch_group_create()!
    
    dispatch_group_enter(group)
    
    var result: String = ""
    let task = NSURLSession.shared().dataTask(with: NSURL(string: url)!) { data, response, error in
        if let data = data, let string = String(data: data, encoding: NSUTF8StringEncoding) {
            result = string
        }
        dispatch_group_leave(group)
    }
    task.resume()
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
    return result
}
func dependencies(package: String, parent: Dependency? = nil) -> [Dependency] {
    let lines = package.components(separatedBy: NSCharacterSet.newlines())
    return lines
        .map { $0.trimmingCharacters(in: NSCharacterSet.whitespaces()) }
        .filter { $0.hasPrefix(".Package(url: ") }
        .flatMap { line in
            let url = line
                .components(separatedBy: ".Package(url: \"")
                .last!
                .components(separatedBy: "\",")
                .first!
            
            if (line.contains("versions:")) {
                let version = line
                    .components(separatedBy: "versions:")
                    .last!
                    .trimmingCharacters(in: NSCharacterSet.whitespaces())
                    .components(separatedBy: "..<")
                    .map { $0.components(separatedBy: "Version(").last!.components(separatedBy: ")").first! }
                    .map { $0.components(separatedBy: ",") }
                
                return Dependency(
                    url: url,
                    minVersion: (Int(version[0][0] ?? "0")!, Int(version[0][1] ?? "0")!, Int(version[0][2] ?? "0")!),
                    maxVersion: (Int(version[1][0] ?? "0")!, Int(version[1][1] ?? "0")!, Int(version[1][2] ?? "0")!),
                    parent: parent
                )
                
            } else {
                let version = line
                    .components(separatedBy: "\",")
                    .last!
                    .components(separatedBy: ")")
                    .first!
                    .trimmingCharacters(in: NSCharacterSet.whitespaces())
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: NSCharacterSet.whitespaces()) }
                    .map { data in
                        return data
                            .components(separatedBy: ":")
                            .map { $0.trimmingCharacters(in: NSCharacterSet.whitespaces()) }
                    }
                    .map { pair in
                        return (key: pair[0], value: pair[1])
                    }
                    .reduce([String: String](), combine: { current, pair in
                        var new = current
                        new[pair.key] = pair.value
                        return new
                    })
                
                return Dependency(
                    url: url,
                    minVersion: (Int(version["majorVersion"] ?? "0")!, Int(version["minor"] ?? "0")!, Int(version["patch"] ?? "0")!),
                    maxVersion: (Int(version["majorVersion"] ?? "0")!, Int(version["minor"] ?? "0")!, Int(version["patch"] ?? "0")!),
                    parent: parent
                )
            }
        }
}

func process(url: String, parent: Dependency? = nil) -> [Dependency] {
    let packageUrl = package(url: url)
    let text = get(url: packageUrl)
    count += 1
    if (showCounts) {
        let countString = String(format: "%02d", count)
        print("\(countString): \(String(repeating: Character("-"), count: indent))\(url)")
    }
    let deps = dependencies(package: text, parent: parent)
    
    var result = deps
    indent += 1
    for dep in deps {
        let subDependencies = process(url: dep.url, parent: dep)
        result.append(contentsOf: subDependencies)
    }
    indent -= 1
    return result
}

do {
    let input = NSProcessInfo.processInfo().arguments.first!
    
    let graph = process(url: input)
    
    var grouped = [String: [Dependency]]()
    for dependency in graph {
        var items = grouped[dependency.url] ?? []
        items.append(dependency)
        grouped[dependency.url] = items
    }
    
    for (url, deps) in grouped {
        print("\nURL: \(url)")
        let versions = deps
            .map {
                let chain = $0.chain().dropFirst().map({ $0.url }).joined(separator: " > ")
                return "\($0.version) from \(chain)"
            }
            .joined(separator: "\n")
        
        print(versions)
    }
}
