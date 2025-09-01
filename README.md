# swift-package-generator

[![CI Status](https://img.shields.io/github/actions/workflow/status/dfed/swift-package-generator/ci.yml?branch=main)](https://github.com/dfed/swift-package-generator/actions?query=workflow%3ACI+branch%3Amain)
[![codecov](https://codecov.io/gh/dfed/swift-package-generator/branch/main/graph/badge.svg?token=nZBHcZZ63F)](https://codecov.io/gh/dfed/swift-package-generator)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://spdx.org/licenses/MIT.html)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdfed%2Fswift-package-generator%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/dfed/swift-package-generator)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdfed%2Fswift-package-generator%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/dfed/swift-package-generator)

A command line tool that generates a Package.swift from distributed definition files.

## Distributed package definition

Swift Package Manager is quite powerful, but it centralizes your project’s entire definition into a single file. On a project with multiple teams, centralizing the package definition can be problematic organizationally.

swift-package-generator enables distributing your proejct definition over multiple files and then stiching them back together with a single command.

SwiftPackageGenerator scans your project directory for:

1. **PackageDescription.swift files** - Contains package configuration arguments like `name`, `platforms`, `products`, `dependencies`, and `targets`.
2. **Subpackage.swift files** - Contains shared utilities, extensions, and helper functions that can be reused across your package.

## Getting Started

### Installation

#### Swift Package Manager

Add SwiftPackageGenerator as a dependency in your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/dfed/swift-package-generator.git", from: "0.1.0"),
]
```

### Basic Usage

Run the command line tool to generate your `Package.swift` file:

```zsh
swift run swift-generate-package
```

For a documented list of available parameters, run:

```zsh
swift run swift-generate-package --help
```

### Example Structure

The project has an [Example](Example/) project with a [top-level package configuration](Example/PackageDescription.swift), a [shared utilities file](Example/Subpackage.swift), and two [example](Example/features/FooFeature/PackageDescription.swift) [modules](Example/libraries/BarLibrary/PackageDescription.swift):

```
MyProject/
├── PackageDescription.swift          # Top-level package configuration
├── Subpackage.swift                  # Shared target utilities
├── features/
│   └── FooFeature/
│       ├── PackageDescription.swift  # Feature-specific targets
│       └── Sources/
└── libraries/
    └── BarLibrary/
        ├── PackageDescription.swift  # Library-specific targets
        └── Sources/
```

You can run the following command to generate its `Package.swift` file:
```zsh
swift run swift-generate-package --root-directory Example/
```

## Contributing

I’m glad you’re interested in swift-package-generator, and I’d love to see where you take it. Please review the [contributing guidelines](Contributing.md) prior to submitting a Pull Request.

Thanks for being part of this journey, and happy packaging!
