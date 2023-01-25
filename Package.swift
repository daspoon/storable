// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Compendium",
    platforms: [ .iOS(.v16), .macOS(.v13) ],
    products: [
      .library(name: "Compendium", targets: ["Compendium"]),
    ],
    dependencies: [
    ],
    targets: [
      .target(name: "Compendium", dependencies: [], path: "Sources"),
      .testTarget(name: "CompendiumTests", dependencies: ["Compendium"], path: "Tests"),
    ]
)
