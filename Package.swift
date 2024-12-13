// swift-tools-version: 5.8.1

import PackageDescription

let package = Package(
    name: "DittoSwiftTools",
    platforms: [
        .iOS(.v14),
        .tvOS(.v15),
    ],
    products: [
        .library(
            name: "DittoHealthMetrics",
            targets: ["DittoHealthMetrics"]
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
        .package(url: "https://github.com/getditto/DittoSwiftPackage", from: "4.8.0"),
        .package(url: "https://github.com/getditto/DittoPresenceViewer.git", branch: "BP/reset"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0")
    ],
    targets: [
        .target(name: "DittoHealthMetrics"),
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
                .product(name: "DittoPresenceViewer", package: "DittoPresenceViewer"),
                "DittoDataBrowser",
                "DittoExportLogs",
                "DittoDiskUsage",
                "DittoPeersList",
                "DittoExportData",
                "DittoPresenceDegradation",
                "DittoHeartbeat",
                "DittoPermissionsHealth"
            ]
        )

    ]
)
