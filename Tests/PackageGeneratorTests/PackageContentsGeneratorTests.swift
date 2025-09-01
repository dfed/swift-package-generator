@testable import PackageGenerator
import XCTest

final class PackageContentsGeneratorTests: XCTestCase {
	// MARK: XCTestCase

	override func setUp() {
		super.setUp()
		stubFileLoader = StubFileLoader()
		systemUnderTest = PackageContentsGenerator(fileLoader: stubFileLoader)
	}

	// MARK: Behavior Tests

	func test_generatePackageContents_includesInputSwiftToolsVersion() throws {
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: "fake",
			usingSwiftToolsVersion: "6.0",
		)
		let swiftToolsVersionLine = try XCTUnwrap(packageFile.split(separator: "\n").first)
		XCTAssertEqual(swiftToolsVersionLine, "// swift-tools-version: 6.0")
	}

	func test_generatePackageContents_utilizesArgumentsFromSubpackageFiles() throws {
		stubFileLoader.nameAndDirectoryToFilesMap[StubFileLoader.NameAndDirectory(
			name: "PackageDescription.swift",
			directory: "fake",
		)] = [
			"""
			let name = "TestPackage"
			""",
			"""
			let platforms = [
				.macOS(.v13)
			]
			""",
			"""
			let products = [
				.library(
					name: "Library"
				),
			]
			""",
		]
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: "fake",
			usingSwiftToolsVersion: "6.0",
		)
		XCTAssertEqual(
			packageFile,
			"""
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
			""",
		)
	}

	func test_generatePackageContents_ignoresTriviaInSubpackageFiles() throws {
		stubFileLoader.nameAndDirectoryToFilesMap[StubFileLoader.NameAndDirectory(
			name: "PackageDescription.swift",
			directory: "fake",
		)] = [
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
		]
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: "fake",
			usingSwiftToolsVersion: "6.0",
		)
		XCTAssertEqual(
			packageFile,
			"""
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
			""",
		)
	}

	func test_generatePackageContents_flattensMultiplePlatformsInSubpackageFiles() throws {
		stubFileLoader.nameAndDirectoryToFilesMap[StubFileLoader.NameAndDirectory(
			name: "PackageDescription.swift",
			directory: "fake",
		)] = [
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
		]
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: "fake",
			usingSwiftToolsVersion: "6.0",
		)
		XCTAssertEqual(
			packageFile,
			"""
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
			""",
		)
	}

	func test_generatePackageContents_throwsErrorWhenSingleValueParameterFoundInMultipleFiles() throws {
		stubFileLoader.nameAndDirectoryToFilesMap[StubFileLoader.NameAndDirectory(
			name: "PackageDescription.swift",
			directory: "fake",
		)] = [
			"""
			let name = "TestPackage"
			""",
			"""
			let name = "RedfinedPackageName"
			""",
		]

		XCTAssertThrowsError(
			try systemUnderTest.generatePackageContents(
				fromFilesInDirectory: "fake",
				usingSwiftToolsVersion: "6.0",
			),
		) { error in
			XCTAssertEqual(error as? TooManyArgumentDefinitionsError, TooManyArgumentDefinitionsError(label: .name))
		}
	}

	func test_generatePackageContents_deduplicatesDependenciesInSubpackageFiles() throws {
		stubFileLoader.nameAndDirectoryToFilesMap[StubFileLoader.NameAndDirectory(
			name: "PackageDescription.swift",
			directory: "fake",
		)] = [
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
		]
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: "fake",
			usingSwiftToolsVersion: "6.0",
		)
		XCTAssertEqual(
			packageFile,
			"""
			// swift-tools-version: 6.0
			// The swift-tools-version declares the minimum version of Swift required to build this package.

			import PackageDescription

			let package = Package(
				dependencies: [
					.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
				]
			)
			""",
		)
	}

	func test_generatePackageContents_appendsPackageMethodsFiles() throws {
		stubFileLoader.nameAndDirectoryToFilesMap[StubFileLoader.NameAndDirectory(
			name: "Subpackage.swift",
			directory: "fake",
		)] = [
			"// File 1",
			"// File 2",
			"// File 3",
		]
		let packageFile = try systemUnderTest.generatePackageContents(
			fromFilesInDirectory: "fake",
			usingSwiftToolsVersion: "6.0",
		)
		XCTAssertEqual(
			packageFile,
			"""
			// swift-tools-version: 6.0
			// The swift-tools-version declares the minimum version of Swift required to build this package.

			import PackageDescription

			let package = Package(

				)

			// File 1

			// File 2

			// File 3
			""",
		)
	}

	// MARK: Private

	private var systemUnderTest = PackageContentsGenerator()
	private var stubFileLoader = StubFileLoader()
}
