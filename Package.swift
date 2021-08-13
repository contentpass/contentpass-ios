// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ContentPass",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ContentPass",
            targets: ["ContentPass"])
    ],
    dependencies: [
        .package(name: "AppAuth", url: "https://github.com/openid/AppAuth-iOS", .exact("1.4.0")),
        .package(name: "Strongbox", url: "https://github.com/granoff/Strongbox", .exact("0.6.1"))
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ContentPass",
            dependencies: [
                .product(name: "AppAuth", package: "AppAuth"),
                .product(name: "Strongbox", package: "Strongbox")
            ],
            path: "Sources"
        )
    ]
)
