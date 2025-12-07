// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "build",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/holzschu/FMake", from: "0.0.19")
    ],
    targets: [
        .executableTarget(
            name: "build",
            dependencies: ["FMake"],
            path: "Sources/build"
        )
    ]
)
