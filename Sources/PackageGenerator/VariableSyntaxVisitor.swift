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

import SwiftSyntax

final class VariableSyntaxVisitor: SyntaxVisitor {

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

    private(set) var packageProperties: [PackageArgument] = []

    private final class PatternSyntaxVisitor: SyntaxVisitor {
        override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
            key = PackageParameter(rawValue: node.identifier.text)
            return .skipChildren
        }

        override func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
            assignedValue = node.value.description
            return .skipChildren
        }

        private(set) var key: PackageParameter?
        private(set) var assignedValue: String = ""

        var packageProperty: PackageArgument? {
            guard let key else { return nil }
            return PackageArgument(
                key: key,
                value: assignedValue)
        }
    }
}
