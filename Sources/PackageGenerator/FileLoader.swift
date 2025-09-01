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

import Foundation

/// A type that can load the contents of files on disk into memory.
final class FileLoader {
	// MARK: Initialization

	init() {}

	// MARK: FileLoader

	/// - Parameters:
	///   - name: The name of the files to find.
	///   - directory: The root directory within which to look.
	/// - Returns: The contents of the files matching the name.
	func loadAllFiles(named name: String, inDirectory directory: String) throws -> [String] {
		var files: [String] = []
		if let enumerator = FileManager.default.enumerator(
			at: URL(filePath: directory),
			includingPropertiesForKeys: nil,
		) {
			for case let fileURL as URL in enumerator where fileURL.lastPathComponent == name {
				try files.append(String(contentsOf: fileURL))
			}
		}
		return files.sorted()
	}
}
