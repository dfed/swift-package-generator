import Foundation
import Testing

@testable import PackageGenerator

final class PackageContentsGeneratorTests {
	// MARK: Initialization

	deinit {
		try? FileManager.default.removeItem(at: temporaryDirectory)
	}

	// MARK: Behavior Tests

	@Test
	func generatePackageContents_includesInputSwiftToolsVersion() throws {
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: temporaryDirectory.path(),
			usingSwiftToolsVersion: "6.0",
		)
		let swiftToolsVersionLine = try #require(packageFile.split(separator: "\n").first)
		#expect(swiftToolsVersionLine == "// swift-tools-version: 6.0")
	}

	@Test
	func generatePackageContents_utilizesArgumentsFromSubpackageFiles() throws {
		try writeFiles(
			named: "PackageDescription.swift",
			content: [
				"""
				let name = "TestPackage"
				""",
				"""
				let platforms = [
					.macOS(.v13)
				]
				""",
				"""
				let targets = [
					"Sample",
				]
				""",
				"""
				let products = [
					.library(
						name: "Library"
					),
				]
				""",
			],
		)
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: temporaryDirectory.path(),
			usingSwiftToolsVersion: "6.0",
		)
		#expect(packageFile == """
		// swift-tools-version: 6.0
		// The swift-tools-version declares the minimum version of Swift required to build this package.

		import PackageDescription

		let package = Package(
			name: "TestPackage",
			platforms: [
				.macOS(.v13)
			],
			products: [
				.library(
					name: "Library"
				)
			],
			targets: [
				"Sample"
			].flatMap(\\.self)
		)
		""")
	}

	@Test
	func generatePackageContents_ignoresTriviaInSubpackageFiles() throws {
		try writeFiles(
			named: "PackageDescription.swift",
			content: [
				"""
				// The name of the project.
				let name = "TestPackage"
				""",
				"""
				let platforms = [
					.macOS(.v13) // We support macOS 13!
				]
				""",
				"""
				let products = [
					.library(
						name: "Library"
					),
				]

				// extra whitespace above
				""",
			],
		)
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: temporaryDirectory.path(),
			usingSwiftToolsVersion: "6.0",
		)
		#expect(packageFile == """
		// swift-tools-version: 6.0
		// The swift-tools-version declares the minimum version of Swift required to build this package.

		import PackageDescription

		let package = Package(
			name: "TestPackage",
			platforms: [
				.macOS(.v13)
			],
			products: [
				.library(
					name: "Library"
				)
			]
		)
		""")
	}

	@Test
	func generatePackageContents_flattensMultiplePlatformsInSubpackageFiles() throws {
		try writeFiles(
			named: "PackageDescription.swift",
			content: [
				"""
				let name = "TestPackage"
				""",
				"""
				let platforms = [
					.macOS(.v13)
				]
				""",
				"""
				let platforms = [
					.iOS(.v13)
				]
				""",
			],
		)
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: temporaryDirectory.path(),
			usingSwiftToolsVersion: "6.0",
		)
		#expect(packageFile == """
		// swift-tools-version: 6.0
		// The swift-tools-version declares the minimum version of Swift required to build this package.

		import PackageDescription

		let package = Package(
			name: "TestPackage",
			platforms: [
				.iOS(.v13),
				.macOS(.v13),
			]
		)
		""")
	}

	@Test
	func generatePackageContents_throwsErrorWhenSingleValueParameterFoundInMultipleFiles() throws {
		try writeFiles(
			named: "PackageDescription.swift",
			content: [
				"""
				let name = "TestPackage"
				""",
				"""
				let name = "RedfinedPackageName"
				""",
			],
		)

		#expect(throws: TooManyArgumentDefinitionsError(label: .name), performing: {
			try self.systemUnderTest.generatePackageContents(
				fromFilesInDirectory: self.temporaryDirectory.path(),
				usingSwiftToolsVersion: "6.0",
			)
		})
	}

	@Test
	func generatePackageContents_deduplicatesDependenciesInSubpackageFiles() throws {
		try writeFiles(
			named: "PackageDescription.swift",
			content: [
				"""
				let dependencies = [
					.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
				]
				""",
				"""
				let dependencies = [
					.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
				]
				""",
			],
		)
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: temporaryDirectory.path(),
			usingSwiftToolsVersion: "6.0",
		)
		#expect(packageFile == """
		// swift-tools-version: 6.0
		// The swift-tools-version declares the minimum version of Swift required to build this package.

		import PackageDescription

		let package = Package(
			dependencies: [
				.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
			]
		)
		""")
	}

	@Test
	func generatePackageContents_appendsPackageMethodsFiles() throws {
		try writeFiles(
			named: "Subpackage.swift",
			content: [
				"// File 1",
				"// File 2",
				"// File 3",
			],
		)
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: temporaryDirectory.path(),
			usingSwiftToolsVersion: "6.0",
		)
		#expect(packageFile == """
		// swift-tools-version: 6.0
		// The swift-tools-version declares the minimum version of Swift required to build this package.

		import PackageDescription

		// File 1

		// File 2

		// File 3

		let package = Package(

			)
		""")
	}

	// MARK: Private

	private let systemUnderTest = PackageContentsGenerator()
	private let temporaryDirectory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)

	var subdirectoryIndex: UInt64 = 0
	private func writeFiles(named: String, content: [String]) throws {
		try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
		for fileContent in content {
			let subdirectory = temporaryDirectory.appending(path: subdirectoryIndex.description)
			try FileManager.default.createDirectory(at: subdirectory, withIntermediateDirectories: true)
			try fileContent.write(
				to: subdirectory.appending(path: named),
				atomically: true,
				encoding: .utf8,
			)
			subdirectoryIndex += 1
		}
	}
}
