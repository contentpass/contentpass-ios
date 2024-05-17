// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "ContentPass",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "ContentPass",
            targets: ["ContentPass"])
    ],
    dependencies: [
        .package(name: "AppAuth", url: "https://github.com/openid/AppAuth-iOS", .exact("1.7.5")),
        .package(name: "Strongbox", url: "https://github.com/granoff/Strongbox", .exact("0.6.1"))
    ],
    targets: [
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
