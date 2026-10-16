// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "Brudcast",
    platforms: [
        .iOS(.v14),
        .macOS(.v12),
    ],
    products: [
        .library(name: "Brudcast", targets: ["Brudcast"]),
        .library(name: "BrudcastInApp", targets: ["BrudcastInApp"]),
        .library(name: "BrudcastPush", targets: ["BrudcastPush"]),
        .library(name: "BrudcastNotificationService", targets: ["BrudcastNotificationService"]),
    ],
    targets: [
        .target(
            name: "Brudcast",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BrudcastInApp",
            dependencies: ["Brudcast"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BrudcastPush",
            dependencies: ["Brudcast", "BrudcastNotificationService"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "BrudcastNotificationService",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(name: "BrudcastTests", dependencies: ["Brudcast"]),
        .testTarget(name: "BrudcastInAppTests", dependencies: ["BrudcastInApp"]),
        .testTarget(name: "BrudcastPushTests", dependencies: ["BrudcastPush", "BrudcastNotificationService"]),
    ]
)
