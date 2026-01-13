// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BerlinTransportMapFeature",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BerlinTransportMapFeature",
            targets: ["BerlinTransportMapFeature"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/alexander-albers/tripkit.git", from: "1.17.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BerlinTransportMapFeature",
            dependencies: [
                .product(name: "TripKit", package: "tripkit"),
            ]
        ),
        .testTarget(
            name: "BerlinTransportMapFeatureTests",
            dependencies: [
                "BerlinTransportMapFeature"
            ]
        ),
    ]
)
