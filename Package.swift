// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Doit",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "DoitCore"),
        .executableTarget(name: "Doit", dependencies: ["DoitCore"]),
        .testTarget(name: "DoitCoreTests", dependencies: ["DoitCore"]),
    ]
)
