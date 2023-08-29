// Distributed under the MIT License
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import ArgumentParser
import Foundation
import SwiftFormat
import SwiftShell
import SwiftSyntax
import SwiftSyntaxParser

public struct GenerateCommand: ParsableCommand {
    public init() {}

    public static var configuration = CommandConfiguration(
        commandName: "swift-generate-package",
        abstract: "A command line tool to help generate Package.swift files.")

    @Option(help: "The root directory in which to search for PackageMethods.swift and Subpackage.swift and files")
    var rootDirectory: String = FileManager.default.currentDirectoryPath

    @Option(help: "The swift-tools-version to use in the generated Package.swift file")
    var swiftToolsVersion: String = "5.8"

    public func run() throws {
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        let currentDirectory = URL(filePath: currentDirectoryPath)
        let packageMethods = try Process.execute(
            """
            find \(rootDirectory) -type f -name "PackageMethods.swift"
            """,
            within: .path(currentDirectoryPath)
        )
            .split(separator: "\n")
            .map {
                try Process.execute("cat \($0)")
            }
            .joined(separator: "\n\n")
        let packageKeyToParametersMap = try Process.execute(
            """
            find . -type f -name "Subpackage.swift"
            """,
            within: .path(currentDirectoryPath)
        )
            .split(separator: "\n")
            .reduce(into: [PackageKey: [String]](), { partialResult, next in
                let syntax = try SyntaxParser.parse(currentDirectory.appending(component: next))
                let visitor = VariableSyntaxVisitor(viewMode: .sourceAccurate)
                visitor.walk(syntax)
                for packageProperty in visitor.packageProperties {
                    partialResult[packageProperty.key, default: []] += [packageProperty.value]
                }
            })
        var packageParameters = [String]()
        for packageKey in PackageKey.allCases {
            guard let parameters = packageKeyToParametersMap[packageKey] else { continue }
            try packageParameters.append(packageKey.combinedParameter(from: parameters))
        }

        let unindentedPackageDeclaration = """
        let package = Package(
        \(packageParameters.joined(separator: ",\n"))
        )
        """

        // Format the Package declaration so it looks nice.
        let parsedPackageDeclaration = try SyntaxParser.parse(
            source: unindentedPackageDeclaration
        )
        let packageFileSyntax = SourceFileSyntax(
            statements: parsedPackageDeclaration.statements,
            eofToken: parsedPackageDeclaration.eofToken
        )
        var packageFileStream = TextStreamReceiver()
        try SwiftFormatter(configuration: .init())
            .format(
                syntax: packageFileSyntax,
                operatorTable: .standardOperators,
                assumingFileURL: nil,
                to: &packageFileStream)

        let packageFile = """
        // swift-tools-version: \(swiftToolsVersion)
        // The swift-tools-version declares the minimum version of Swift required to build this package.

        import PackageDescription

        \(packageFileStream.text)
        extension Array {
            static func flatten(_ targets: [[Element]]) -> [Element] {
                targets.flatMap { $0 }
            }
        }

        \(packageMethods)
        """

        try packageFile.write(
            to: URL(filePath: rootDirectory).appending(component: "Package.swift"),
            atomically: true,
            encoding: .utf8)
    }
}

enum PackageKey: String, CaseIterable {
    case name
    case defaultLocalization
    case platforms
    case pkgConfig
    case providers
    case products
    case dependencies
    case targets
    case swiftLanguageVersions
    case cLanguageStandard
    case cxxLanguageStandard

    func combinedParameter(from values: [String]) throws -> String {
        switch self {
        case .cLanguageStandard,
                .cxxLanguageStandard,
                .dependencies,
                .platforms,
                .products,
                .providers,
                .swiftLanguageVersions,
                .targets:
            return """
                   \(self.rawValue): .flatten([
                       \(values.joined(separator: ",\n"))
                   ])
                   """
        case .defaultLocalization,
                .name,
                .pkgConfig:
            if values.count > 1 {
                struct TooManyArgumentDefinitionsError: Error {
                    let key: PackageKey
                }
                throw TooManyArgumentDefinitionsError(key: self)

            } else if let value = values.first {
                return "\(self.rawValue): \(value)"

            } else {
                struct TooFewArgumentDefinitionsError: Error {
                    let key: PackageKey
                }
                throw TooFewArgumentDefinitionsError(key: self)
            }
        }
    }
}

struct PackageProperty {
    let key: PackageKey
    let value: String
}

private final class VariableSyntaxVisitor: SyntaxVisitor {

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        packageProperties.append(
            contentsOf: node
                .bindings
                .compactMap {
                    let patternVisitor = PatternSyntaxVisitor(viewMode: .sourceAccurate)
                    patternVisitor.walk($0)
                    return patternVisitor.packageProperty
                }
        )

        return .skipChildren
    }

    private(set) var packageProperties: [PackageProperty] = []

    private final class PatternSyntaxVisitor: SyntaxVisitor {
        override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
            key = PackageKey(rawValue: node.identifier.text)
            return .skipChildren
        }

        override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
            assignedValue = node.value.description
            return .skipChildren
        }

        private(set) var key: PackageKey?
        private(set) var assignedValue: String = ""

        var packageProperty: PackageProperty? {
            guard let key else { return nil }
            return PackageProperty(
                key: key,
                value: assignedValue)
        }
    }
}

struct TextStreamReceiver: TextOutputStream {
    var text = ""

    mutating func write(_ streamedText: String) {
        text += streamedText
    }
}
