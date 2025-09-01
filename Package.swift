// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwiftPackageGenerator",
	platforms: [
		.macOS(.v13),
	],
	products: [
		.executable(
			name: "swift-generate-package",
			targets: ["GeneratePackage"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
		.package(url: "https://github.com/swiftlang/swift-format.git", "600.0.0"..<"602.0.0"),
		.package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"602.0.0"),
		.package(url: "https://github.com/dfed/swift-shell", from: "0.1.0"),
	],
	targets: [
		.executableTarget(
			name: "GeneratePackage",
			dependencies: [
				"PackageGenerator",
			]
		),
		.target(
			name: "PackageGenerator",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				.product(name: "SwiftFormat", package: "swift-format"),
				.product(name: "SwiftParser", package: "swift-syntax"),
				.product(name: "SwiftShell", package: "swift-shell"),
			]
		),
		.testTarget(
			name: "PackageGeneratorTests",
			dependencies: ["PackageGenerator"]
		),
	]
)
