// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "DittoSwiftTools",
    platforms: [
        .iOS(.v11),
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "DittoPresenceViewer",
            targets: ["DittoPresenceViewer"]),
        .library(
            name: "DittoDataBrowser",
             targets: ["DittoDataBrowser"]),
        .library(
            name: "DittoExportLogs",
            targets: ["DittoExportLogs"]),
        .library(
            name: "DittoDiskUsage",
            targets: ["DittoDiskUsage"]),
        .library(
            name: "DittoPeersList",
            targets: ["DittoPeersList"]),
        .library(
            name: "DittoExportData",
            targets: ["DittoExportData"]),
    ],
    dependencies: [
        .package(url: "https://github.com/getditto/DittoSwiftPackage", from: "4.0.0"),
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
    ]
)
