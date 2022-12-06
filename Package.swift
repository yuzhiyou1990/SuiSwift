// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SuiSwift",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SuiSwift",
            targets: ["SuiSwift"]),
    ],
    dependencies: [
        .package(name: "TweetNacl", url: "https://github.com/lishuailibertine/tweetnacl-swiftwrap", from: "1.0.5"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.4.2"),
        .package(url: "https://github.com/mathwallet/BIP39swift", from: "1.0.1"),
        .package(url: "https://github.com/mxcl/PromiseKit.git", from: "6.8.4"),
        .package(name: "Secp256k1Swift", url: "https://github.com/mathwallet/Secp256k1Swift.git", from: "1.3.1"),
        .package(name:"Blake2",url: "https://github.com/tesseract-one/Blake2.swift.git", from: "0.1.2"),
        .package(url: "https://github.com/attaswift/BigInt", from: "5.3.0"),
        .package(url: "https://github.com/Flight-School/AnyCodable.git", .exact("0.6.1")),
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SuiSwift",
            dependencies: ["CryptoSwift", "TweetNacl", "BIP39swift", "PromiseKit", "Secp256k1Swift", "Blake2", "BigInt", "AnyCodable", .product(name: "BIP32Swift", package: "Secp256k1Swift")]),
        .testTarget(
            name: "SuiSwiftTests",
            dependencies: ["SuiSwift"]),
    ]
)
