// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "DittoSwiftTools",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .visionOS(.v1),
    ],
    products: [
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
    ],
    dependencies: [
        // Ditto.diskUsage was added in 3.0.1
        .package(url: "file:///Users/phatblat/dev/ditto/DittoSwiftPackage", from: "4.0.0"),
        .package(url: "git@github.com:apple/swift-collections.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "DittoPresenceViewer",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "Sources/DittoPresenceViewer",
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
            ],
            path: "Sources/DittoDataBrowser"
        ),
        .target(
            name: "DittoExportLogs",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "Sources/DittoExportLogs"
        ),
        .target(
            name: "DittoDiskUsage",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "Sources/DittoDiskUsage"
        ),
        .target(
            name: "DittoPeersList",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "Sources/DittoPeersList"
        ),
        .target(
            name: "DittoExportData",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "Sources/DittoExportData"
        ),
        .target(
            name: "DittoPresenceDegradation",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "Sources/DittoPresenceDegradation"
        ),
        .target(
            name: "DittoHeartbeat",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "Sources/DittoHeartbeat"
        ),
        .target(
            name: "DittoPermissionsHealth",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "Sources/DittoPermissionsHealth"
        ),
    ]
)
