// swift-tools-version: 6.0

import PackageDescription

// DITTO_DEFAULT_SDK_VERSION: 5.0.1
// This is the minimum Ditto SDK version for the next tools release. Raising it
// requires a new major version of DittoSwiftTools.

let package = Package(
    name: "DittoSwiftTools",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "DittoHealthMetrics",
            targets: ["DittoHealthMetrics"]
        ),
        .library(
            name: "DittoPresenceViewer",
            targets: ["DittoPresenceViewer"]
        ),
        .library(
            name: "DittoDataBrowser",
            targets: ["DittoDataBrowser"]
        ),
        .library(
            name: "DittoExportLogs",
            targets: ["DittoExportLogs"]
        ),
        .library(
            name: "DittoDiskUsage",
            targets: ["DittoDiskUsage"]
        ),
        .library(
            name: "DittoPeersList",
            targets: ["DittoPeersList"]
        ),
        .library(
            name: "DittoExportData",
            targets: ["DittoExportData"]
        ),
        .library(
            name: "DittoPresenceDegradation",
            targets: ["DittoPresenceDegradation"]
        ),
        .library(
            name: "DittoHeartbeat",
            targets: ["DittoHeartbeat"]
        ),
        .library(
            name: "DittoPermissionsHealth",
            targets: ["DittoPermissionsHealth"]),
        .library(
            name: "DittoAllToolsMenu",
            targets: ["DittoAllToolsMenu"]),
    ],
    dependencies: [
        .package(url: "https://github.com/getditto/DittoSwiftPackage", from: "5.0.1"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "DittoPresenceViewerCore",
            path: "Sources/DittoPresenceViewerCore",
            resources: [
                .copy("Resources/dist"),
            ]
        ),
        .target(name: "DittoHealthMetrics"),
        .target(
            name: "DittoPresenceViewer",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage"),
                "DittoPresenceViewerCore",
            ]
        ),
        .target(
            name: "DittoDataBrowser",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage"),
                .product(name: "OrderedCollections", package: "swift-collections")
            ]
        ),
        .target(
            name: "DittoExportLogs",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ]
        ),
        .target(
            name: "DittoDiskUsage",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage"),
                "DittoHealthMetrics",
                "DittoExportData"
            ]
        ),
        .target(
            name: "DittoPeersList",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ]
        ),
        .target(
            name: "DittoExportData",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ]
        ),
        .target(
            name: "DittoPresenceDegradation",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ]
        ),
        .target(
            name: "DittoHeartbeat",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage"),
                "DittoHealthMetrics"
            ]
        ),
        .target(
            name: "DittoPermissionsHealth",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage"),
                "DittoHealthMetrics"
            ]
        ),
        .target(
            name: "DittoAllToolsMenu",
            dependencies: [
                "DittoHealthMetrics",
                "DittoPresenceViewer",
                "DittoDataBrowser",
                "DittoExportLogs",
                "DittoDiskUsage",
                "DittoPeersList",
                "DittoExportData",
                "DittoPresenceDegradation",
                "DittoHeartbeat",
                "DittoPermissionsHealth"
            ]
        ),
        .testTarget(
            name: "DittoHeartbeatTests",
            dependencies: ["DittoHeartbeat"]
        ),
        .testTarget(
            name: "DittoPresenceDegradationTests",
            dependencies: [
                "DittoPresenceDegradation",
                .product(name: "DittoSwift", package: "DittoSwiftPackage"),
            ]
        ),
    ],
    // DittoSwiftPackage 5.0.1 requires a Swift 6 toolchain. Keep the tools
    // source in its existing Swift 5 language mode for this focused release;
    // adopting Swift 6 language semantics requires separate concurrency work.
    swiftLanguageModes: [.v5]
)
