extension Target {

    static func feature(
        name: String,
        dependencies: [Target.Dependency],
        testDependencies: [Target.Dependency] = [])
    -> [Target]
    {
        TargetKind(
            path: "features",
            suffix: "Feature",
            visibility: .targetType(suffixes: ["Feature"]))
        .firstPartyTarget(
            named: name,
            dependencies: dependencies,
            testDependencies: testDependencies)
    }

    static func library(
        name: String,
        dependencies: [Target.Dependency],
        testDependencies: [Target.Dependency] = [])
    -> [Target]
    {
        TargetKind(
            path: "libraries",
            suffix: "Library",
            visibility: .targetType(suffixes: ["Feature", "Library"]))
        .firstPartyTarget(
            named: name,
            dependencies: dependencies,
            testDependencies: testDependencies)
    }
}


enum RestrictedVisibility {
    case targets(Set<String>)
    case targetType(suffixes: [String])
}

struct VisibilityValidator {
    static func validateDependencies(from target: FirstPartyTarget) {
        let targetName = target.targetName
        allDependencies[targetName] = target.dependencies
        allRestrictedVisibility[targetName] = target.kind.visibility

        validate()
    }

    private static var allDependencies = [String: [Target.Dependency]]()
    private static var allRestrictedVisibility = [String: RestrictedVisibility]()

    private static func validate() {
        for (target, dependencies) in allDependencies {
            for dependency in dependencies {
                guard let restrictedVisibility = allRestrictedVisibility[dependency.name] else {
                    // There are no visibility restrictions for this dependency.
                    continue
                }

                switch restrictedVisibility {
                case .targets(let targets):
                    assert(targets.contains(target), "\(target) depends on \(dependency.name), which is not allowed")
                case .targetType(let suffixes):
                    assert(!suffixes.filter { target.hasSuffix($0) }.isEmpty, "\(target) depends on \(dependency.name), which is not allowed")
                }
            }
        }
    }
}

struct TargetKind {
    init(path: String, suffix: String, visibility: RestrictedVisibility? = nil) {
        self.path = path.withTrailingSlash
        self.suffix = suffix
        self.visibility = visibility
    }

    let path: String
    let suffix: String
    let visibility: RestrictedVisibility?

    func firstPartyTarget(
        named name: String,
        dependencies: [Target.Dependency],
        testDependencies: [Target.Dependency])
    -> [Target]
    {
        let target = FirstPartyTarget(
            name: name,
            kind: self,
            dependencies: dependencies,
            testDependencies: testDependencies)
        let targetName = target.targetName
        VisibilityValidator.validateDependencies(from: target)
        return [
            .target(
                name: targetName,
                dependencies: dependencies,
                path: target.sourcesPath),
            .testTarget(
                name: targetName + "Tests",
                dependencies: dependencies + testDependencies,
                path: target.testsPath)
        ]
    }
}

struct FirstPartyTarget {
    let name: String
    let kind: TargetKind
    let dependencies: [Target.Dependency]
    let testDependencies: [Target.Dependency]

    var targetName: String {
        name + kind.suffix
    }

    var sourcesPath: String {
        kind.path + targetName + "/Sources"
    }

    var testsPath: String {
        kind.path + targetName + "/Tests"
    }
}

extension Target.Dependency {
    var name: String {
        switch self {
        case .byNameItem(let name, _): return name
        case .productItem(let name, _, _, _): return name
        case .targetItem(let name, _): return name
        @unknown default:
            fatalError("Unknown case \(self)")
        }
    }
}

extension String {
    var withTrailingSlash: String {
        self + (self.hasSuffix("/") ? "" : "/")
    }
}
