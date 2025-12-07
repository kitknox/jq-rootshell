// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "build",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/FMake", from: "0.0.32")
    ],
    targets: [
        .executableTarget(
            name: "build",
            dependencies: ["FMake"],
            path: "Sources/build"
        )
    ]
)
