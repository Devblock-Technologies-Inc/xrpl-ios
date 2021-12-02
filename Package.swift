// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xrpl-ios",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "xrpl-ios",
            targets: ["xrpl-ios"]),
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt", .branch("master")),
        .package(url: "https://github.com/apple/swift-crypto.git", .upToNextMajor(from: "2.0.0")),
    ],
    targets: [
        .target(
            name: "xrpl-ios",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Crypto", package: "swift-crypto")
            ]),
        .testTarget(
            name: "xrpl-iosTests",
            dependencies: ["xrpl-ios"]),
    ]
)
