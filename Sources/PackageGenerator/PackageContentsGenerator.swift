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

/// Generates a `Package.swift` file from `PackageMethods.swift` and `Subpackage.swift`.
public final class PackageContentsGenerator {

    // MARK: Initialization

    public convenience init() {
        self.init(
            fileLoader: DefaultFileLoader()
        )
    }

    required init(fileLoader: FileLoader) {
        self.fileLoader = fileLoader
    }

    // MARK: Public

    public func generatePackageContents(
        fromFilesInDirectory directory: String,
        usingSwiftToolsVersion swiftToolsVersion: String
    ) throws -> String {
        let packageDefinitionResolver = PackageDefinitionResolver(fileLoader: fileLoader)

        let packageDefinition = try packageDefinitionResolver.resolvePackageFromSubpackageFiles(inDirectory: directory)

        let packageMethods = try fileLoader
            .loadAllFiles(
                named: "PackageMethods.swift",
                inDirectory: directory)
        let allPackageMethods: String
        if packageMethods.isEmpty {
            allPackageMethods = ""
        } else {
            allPackageMethods = "\n\n\(packageMethods.joined(separator: "\n\n"))"
        }

        return """
        // swift-tools-version: \(swiftToolsVersion)
        // The swift-tools-version declares the minimum version of Swift required to build this package.

        import PackageDescription

        \(packageDefinition)
        extension Array {
            static func flatten(_ targets: [[Element]]) -> [Element] {
                targets.flatMap { $0 }
            }
        }
        """.appending(allPackageMethods)
    }

    // MARK: Private

    private let fileLoader: FileLoader

}
