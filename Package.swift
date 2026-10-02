// swift-tools-version:6.3
import PackageDescription

let package = Package(
    name: "lineup",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.121.4"),
        // An ORM for SQL and NoSQL databases.
        .package(url: "https://github.com/vapor/fluent.git", from: "4.13.0"),
        // Fluent driver for MySQL.
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.8.0"),
        // Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.101.0"),
        // JWT Token Auth
        .package(url: "https://github.com/vapor/jwt", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "lineup",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "JWT", package: "jwt")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "lineupTests",
            dependencies: [
                .target(name: "lineup"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("ImmutableWeakCaptures"),
] }
