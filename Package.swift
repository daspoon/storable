// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Storable",
    platforms: [.macOS(.v12), .iOS(.v15), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(name: "Storable", targets: ["Storable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .target(name: "Storable", dependencies: ["StorableMacros"]),
        .macro(name: "StorableMacros", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
        ]),
        .testTarget(name: "StorableTests", dependencies: [
            "Storable",
            .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
        ]),
    ]
)
