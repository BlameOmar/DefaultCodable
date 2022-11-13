// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "DefaultCodable",
    products: [
        .library(name: "DefaultCodable", targets: ["DefaultCodable"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "DefaultCodable", dependencies: []),
        .testTarget(name: "DefaultCodableTests", dependencies: ["DefaultCodable"]),
    ]
)
