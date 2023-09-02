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
import PackageGenerator

struct GenerateCommand: ParsableCommand {
    init() {}

    static var configuration = CommandConfiguration(
        commandName: "swift-generate-package",
        abstract: "A command line tool to help generate Package.swift files.")

    @Option(help: "The root directory in which to search for PackageMethods.swift and Subpackage.swift and files")
    var rootDirectory: String = FileManager.default.currentDirectoryPath

    @Option(help: "The swift-tools-version to use in the generated Package.swift file")
    var swiftToolsVersion: String = "5.8"

    func run() throws {
        try PackageContentsGenerator()
            .generatePackageContents(
                fromFilesInDirectory: rootDirectory,
                usingSwiftToolsVersion: swiftToolsVersion
            )
            .write(
                to: URL(filePath: rootDirectory).appending(component: "Package.swift"),
                atomically: true,
                encoding: .utf8
            )
    }
}

