let name = "Scratch"
let platforms = [
	.macOS(.v13),
]
let products = [
	.library(
		name: "Scratch",
		targets: [
			"FooFeature",
			"BarLibrary",
		]
	),
]
