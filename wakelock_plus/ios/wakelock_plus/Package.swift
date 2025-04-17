// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "wakelock_plus",
    platforms: [
        .iOS("11.0")
    ],
    products: [
        .library(name: "wakelock-plus", targets: ["wakelock_plus"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "wakelock_plus",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ],
            cSettings: [
                .headerSearchPath("include/wakelock_plus")
            ]
        )
    ]
)