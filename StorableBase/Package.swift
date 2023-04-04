// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "StorableBase",
    platforms: [ .iOS(.v16), .macOS(.v13) ],
    products: [
        .library(name: "StorableBase", targets: ["StorableBase"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "StorableBase", dependencies: [], path: "Sources"),
    ]
)
