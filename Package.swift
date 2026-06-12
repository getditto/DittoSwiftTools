// swift-tools-version: 5.8.1

import PackageDescription

// PUBLISHING NOTE: At publish time, the DittoSwiftPackage path dep below is
// swapped for its URL-based equivalent, the DittoPresenceViewerCore path dep is
// removed (its source is vendored as an internal target instead), and a
// DittoPresenceViewerCore target declaration is inserted — see PUBLISHING.md.
//
// DITTO_DEFAULT_SDK_VERSION: 5.0.1
// When the publish workflow runs without an explicit SDK version, the
// DittoSwiftPackage URL dependency is pinned to this version. Keep it current
// with the latest published Swift SDK.

let package = Package(
    name: "DittoSwiftTools",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15),
        .tvOS(.v15),
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
        .library(
            name: "DittoTvOSTextFieldComponent",
            targets: ["DittoTvOSTextFieldComponent"]),
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
                .product(name: "DittoSwift", package: "DittoSwiftPackage"),
                "DittoTvOSTextFieldComponent"
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
        .target(
            name: "DittoTvOSTextFieldComponent"
        )
    ]
)
