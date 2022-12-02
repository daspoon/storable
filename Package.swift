// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Compendium",
    platforms: [ .iOS(.v15) ],
    products: [
        .library(name: "Compendium", targets: ["Compendium"]),
    ],
    dependencies: [
      .package(path: "../Schema"),
    ],
    targets: [
        .target(name: "Compendium", dependencies: [.product(name: "Schema", package: "Schema")], path: "Sources"),
        .testTarget(name: "CompendiumTests", dependencies: ["Compendium"], path: "Tests"),
    ]
)
