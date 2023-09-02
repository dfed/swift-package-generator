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

/// An enumeration of the parameters to the Package(...) initializer in PackageDescription.
enum PackageParameter: String, CaseIterable {
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

    /// Takes a series of values for a single key and returns a combined value for use in a generated Package.swift file.
    /// - Parameter values: The values for the Package parameter.
    /// - Returns: A single string representing the combined values for this Package parameter.
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
                    let key: PackageParameter
                }
                throw TooManyArgumentDefinitionsError(key: self)

            } else if let value = values.first {
                return "\(self.rawValue): \(value)"

            } else {
                struct TooFewArgumentDefinitionsError: Error {
                    let key: PackageParameter
                }
                throw TooFewArgumentDefinitionsError(key: self)
            }
        }
    }
}
