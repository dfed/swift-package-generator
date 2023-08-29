// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftPackageGenerator",
    platforms: [
      .macOS(.v13)
    ],
    products: [
      .executable(
        name: "swift-generate-package",
        targets: ["GeneratePackage"]),
    ],
    dependencies: [
      .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
      .package(url: "https://github.com/apple/swift-format", from: "508.0.0"),
      .package(url: "https://github.com/apple/swift-syntax", from: "508.0.0"),
      .package(url: "https://github.com/dfed/swift-shell", from: "0.0.1")
    ],
    targets: [
        .executableTarget(
            name: "GeneratePackage",
            dependencies: [
              "PackageGenerator",
            ]),
        .target(
            name: "PackageGenerator",
            dependencies: [
              .product(name: "ArgumentParser", package: "swift-argument-parser"),
              .product(name: "SwiftFormat", package: "swift-format"),
              .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
              .product(name: "SwiftShell", package: "swift-shell"),
            ]),
        .testTarget(
            name: "PackageGeneratorTests",
            dependencies: ["PackageGenerator"]),
    ]
)
