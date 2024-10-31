// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FunctionCalling-AnthropicSwiftSDK",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FunctionCalling-AnthropicSwiftSDK",
            targets: ["FunctionCalling-AnthropicSwiftSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/FunctionCalling/FunctionCalling.git", from: "0.5.0"),
        .package(url: "https://github.com/fumito-ito/AnthropicSwiftSDK", from: "0.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FunctionCalling-AnthropicSwiftSDK",
            dependencies: [
                .product(name: "FunctionCalling", package: "FunctionCalling"),
                .product(name: "AnthropicSwiftSDK", package: "AnthropicSwiftSDK")
            ]
        ),
        .testTarget(
            name: "FunctionCalling-AnthropicSwiftSDKTests",
            dependencies: ["FunctionCalling-AnthropicSwiftSDK"]
        ),
    ]
)
