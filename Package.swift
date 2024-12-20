// swift-tools-version: 5.8.1

import PackageDescription

let package = Package(
    name: "DittoSwiftTools",
    platforms: [
        .iOS(.v14),
        .macCatalyst(.v14),
        .tvOS(.v15),
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
        .package(url: "https://github.com/getditto/DittoSwiftPackage", from: "4.8.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.0.0")
    ],
    targets: [
        .target(name: "DittoHealthMetrics"),
        .target(
            name: "DittoPresenceViewer",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            resources: [
                .copy("Resources/index.html"),
                .copy("Resources/main.css"),
                .copy("Resources/main.js"),
            ],
            cxxSettings: [
                .define("ENABLE_BITCODE", to: "NO")
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
        )

    ]
)
