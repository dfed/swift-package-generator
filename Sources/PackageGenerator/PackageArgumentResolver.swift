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

import SwiftFormat
import SwiftFormatConfiguration
import SwiftSyntax
import SwiftParser

final class PackageDefinitionResolver {

    // MARK: Initialization

    init(fileLoader: FileLoader = DefaultFileLoader()) {
        self.fileLoader = fileLoader
    }

    // MARK: PackageDefinitionResolver

    /// Creates a `let package = Package(...)` definition from the arguments found in `PackageDescription.swift` files in the given directory..
    /// - Parameter directory: The directory in which to recursively search for the `PackageDescription.swift` files.
    /// - Returns: The Package's definition.
    func resolvePackageFromDescriptionFiles(inDirectory directory: String) throws -> String {
        let packageParameterToParametersMap = try fileLoader
            .loadAllFiles(
                named: "PackageDescription.swift",
                inDirectory: directory
            )
            .reduce(into: [PackageParameter: Set<String>]()) { partialResult, packageDescription in
                let syntax = Parser.parse(source: packageDescription)
                let visitor = VariableSyntaxVisitor(viewMode: .sourceAccurate)
                visitor.walk(syntax)
                for packageProperty in visitor.packageProperties {
                    partialResult[packageProperty.label, default: []].formUnion(packageProperty.values)
                }
            }
        var packageParameters = [String]()
        for packageParameter in PackageParameter.allCases {
            guard let parameters = packageParameterToParametersMap[packageParameter] else { continue }
            try packageParameters.append(packageParameter.combinedParameter(from: parameters.sorted()))
        }

        let unformattedPackageDeclaration = """
        let package = Package(
        \(packageParameters.joined(separator: ",\n"))
        )
        """

        // Format the Package declaration so it looks nice.
        let parsedPackageDeclaration = Parser.parse(
            source: unformattedPackageDeclaration
        )
        let packageFileSyntax = SourceFileSyntax(
            statements: parsedPackageDeclaration.statements,
            endOfFileToken: parsedPackageDeclaration.endOfFileToken
        )
        var packageFileStream = TextStreamReceiver()
        var configuration = Configuration()
        configuration.indentation = .spaces(4)
        try SwiftFormatter(configuration: configuration)
            .format(
                syntax: packageFileSyntax,
                operatorTable: .standardOperators,
                assumingFileURL: nil,
                to: &packageFileStream)

        return packageFileStream.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Private

    private let fileLoader: FileLoader

    // MARK: - TextStreamReceiver

    private struct TextStreamReceiver: TextOutputStream {
        var text = ""

        mutating func write(_ streamedText: String) {
            text += streamedText
        }
    }
}
