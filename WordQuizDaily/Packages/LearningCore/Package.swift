// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LearningCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "LearningCore", targets: ["LearningCore"])],
    targets: [
        .target(name: "LearningCore", resources: [.process("Resources")]),
        .testTarget(name: "LearningCoreTests", dependencies: ["LearningCore"])
    ]
)
