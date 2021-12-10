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
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.4.2")),
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", .upToNextMajor(from: "0.3.3")),
        .package(url: "https://github.com/krzyzanowskim/OpenSSL.git", .upToNextMinor(from: "1.1.180"))
    ],
    targets: [
        .target(
            name: "xrpl-ios",
            dependencies: [
                .product(name: "BigInt", package: "BigInt"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .target(name: "xrpl-private")
            ]),
        .target(name: "xrpl-private",
                dependencies: [
                    .product(name: "secp256k1", package: "secp256k1.swift"),
                    .product(name: "OpenSSL", package: "OpenSSL")
                ]),
        .testTarget(
            name: "xrpl-iosTests",
            dependencies: ["xrpl-ios"]),
    ]
)
