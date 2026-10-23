// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Pipka",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Pipka", path: "Sources/Pipka")
    ]
)
