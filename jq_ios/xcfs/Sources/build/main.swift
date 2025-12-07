// use it from root folder:
// `swift run --package-path xcfs build`

import FMake
import Foundation

OutputLevel.default = .error

let scheme = "jq_ios"
let project = "jq_ios.xcodeproj"

// Standard platforms via FMake
let platforms: [Platform] = [.iPhoneOS, .iPhoneSimulator, .Catalyst]

// Additional visionOS platforms
let additionalPlatforms = ["xros", "xrsimulator"]

// Clean any previous builds
try? sh("rm -rf .build")
try sh("mkdir -p .build")

print("Building \(scheme) for all platforms...")

// Archive for standard platforms using FMake
try xbArchive(
    dirPath: ".build",
    project: project,
    scheme: scheme,
    platforms: platforms.map { ($0, excludedArchs: $0 == .iPhoneSimulator ? [.x86_64] : []) }
)

// Archive for visionOS platforms manually
for platform in additionalPlatforms {
    let archivePath = ".build/\(scheme)-\(platform).xcarchive"
    print("Archiving \(scheme) for \(platform)...")
    try sh("""
        xcodebuild archive \
            -project \(project) \
            -scheme \(scheme) \
            -sdk \(platform) \
            -archivePath \(archivePath) \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            SKIP_INSTALL=NO \
            EXCLUDED_ARCHS=x86_64
        """)
}

// Create xcframework
print("Creating xcframework...")
try cd(".build") {
    var frameworkArgs = [String]()
    let currentDir = FileManager.default.currentDirectoryPath

    // Add standard platform archives
    for p in platforms {
        let xcarchive = "\(currentDir)/\(scheme)-\(p).xcarchive"
        let framework = "\(xcarchive)/Products/Library/Frameworks/\(scheme).framework"
        let dsym = "\(xcarchive)/dSYMs/\(scheme).framework.dSYM"
        frameworkArgs.append("-framework \(framework)")
        if FileManager.default.fileExists(atPath: dsym) {
            frameworkArgs.append("-debug-symbols \(dsym)")
        }
    }

    // Add visionOS archives
    for platform in additionalPlatforms {
        let xcarchive = "\(currentDir)/\(scheme)-\(platform).xcarchive"
        let framework = "\(xcarchive)/Products/Library/Frameworks/\(scheme).framework"
        let dsym = "\(xcarchive)/dSYMs/\(scheme).framework.dSYM"
        frameworkArgs.append("-framework \(framework)")
        if FileManager.default.fileExists(atPath: dsym) {
            frameworkArgs.append("-debug-symbols \(dsym)")
        }
    }

    try? sh("rm -rf \(scheme).xcframework")
    try sh("xcodebuild -create-xcframework \(frameworkArgs.joined(separator: " ")) -output \(scheme).xcframework")

    // Zip for distribution
    print("Creating distribution zip...")
    try sh("zip --symlinks -r \(scheme).xcframework.zip \(scheme).xcframework")

    // Generate checksum
    let checksum = try sha(path: "\(scheme).xcframework.zip")
    print("\nBuild complete!")
    print("Output: .build/\(scheme).xcframework")
    print("Zip: .build/\(scheme).xcframework.zip")
    print("Checksum: \(checksum)")
}
