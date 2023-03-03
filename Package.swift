// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "Storable",
    platforms: [ .iOS(.v16), .macOS(.v13) ],
    products: [
      .library(name: "Storable", targets: ["Storable"]),
    ],
    dependencies: [
    ],
    targets: [
      .target(name: "Storable", dependencies: [], path: "Sources"),
      .testTarget(name: "StorableTests", dependencies: ["Storable"], path: "Tests"),
    ]
)
