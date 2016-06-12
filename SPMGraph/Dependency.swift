//
//  Dependency.swift
//  SPMGraph
//
//  Created by Ian Keen on 12/06/2016.
//
//

class Dependency: Hashable, CustomStringConvertible {
    let parent: Dependency?
    
    let url: String
    let minVersion: (Int, Int, Int)
    let maxVersion: (Int, Int, Int)
    
    var description: String {
        return "\(url): \(version)"
    }
    var version: String {
        return (minVersion == maxVersion
            ? "\(minVersion.0).\(minVersion.1).\(minVersion.2)"
            : "\(minVersion.0).\(minVersion.1).\(minVersion.2)..<\(maxVersion.0).\(maxVersion.1).\(maxVersion.2)"
        )
    }
    var hashValue: Int { return self.description.hashValue }
    var root: Dependency {
        guard let parent = self.parent else { return self }
        return parent.root
    }
    func chain(previous: [Dependency] = []) -> [Dependency] {
        let current = previous + [self]
        guard let parent = self.parent else { return current }
        return parent.chain(previous: current)
    }
    
    init(url: String, minVersion: (Int, Int, Int), maxVersion: (Int, Int, Int), parent: Dependency?) {
        self.parent = parent
        self.url = url
        self.minVersion = minVersion
        self.maxVersion = maxVersion
    }
}
func ==(left: Dependency, right: Dependency) -> Bool {
    return left.description == right.description
}
