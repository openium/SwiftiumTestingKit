// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
// https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md

import PackageDescription

let package = Package(
    name: "SwiftiumTestingKit",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftiumTestingKit",
            targets: ["SwiftiumTestingKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
        .package(url: "https://github.com/openium/KIF", .branch("spm-support-freez")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "SwiftiumTestingKit",
            dependencies: [
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
                "KIF",
            ]),
        .testTarget(
            name: "SwiftiumTestingKitTests",
            dependencies: ["SwiftiumTestingKit"]),
    ]
)
