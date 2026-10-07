// swift-tools-version:6.2
import PackageDescription

let package: Package = .init(
    name: "aura",
    platforms: [.macOS(.v15), .iOS(.v18), .tvOS(.v18), .visionOS(.v2), .watchOS(.v11)],
    products: [
        .executable(name: "aura", targets: ["AuraCLI"]),
        .library(name: "Aura", targets: ["Aura"]),
        .library(name: "AuraDecoding", targets: ["AuraDecoding"]),
        .library(name: "AuraEncoding", targets: ["AuraEncoding"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ordo-one/dollup", from: "1.0.1"),

        .package(url: "https://github.com/rarestype/h", from: "1.0.1"),
        .package(url: "https://github.com/rarestype/swift-io", from: "3.2.0"),
        .package(url: "https://github.com/rarestype/swift-ion", from: "2.2.1"),
        .package(url: "https://github.com/tayloraswift/swift-png", from: "4.5.1"),
    ],
    targets: [
        .target(
            name: "AuraDecoding",
        ),
        .target(
            name: "AuraEncoding",
        ),
        .target(
            name: "Aura",
            dependencies: [
                .target(name: "AuraDecoding"),
                .target(name: "AuraEncoding"),
                .product(name: "Ion", package: "swift-ion"),
                .product(name: "LZ77", package: "swift-png"),
            ]
        ),
        .target(
            name: "AuraTesting",
            dependencies: [
                .target(name: "Aura"),
            ]
        ),
        .executableTarget(
            name: "AuraCLI",
            dependencies: [
                .target(name: "Aura"),
                .product(name: "IonText", package: "swift-ion"),
                .product(name: "SystemIO", package: "swift-io"),
                .product(name: "System_ArgumentParser", package: "swift-io"),
            ]
        ),
        .executableTarget(
            name: "AuraGoldenTests",
            dependencies: [
                .target(name: "Aura"),
                .target(name: "AuraTesting"),
                .product(name: "CRC", package: "h"),
                .product(name: "SystemIO", package: "swift-io"),
                .product(name: "System_ArgumentParser", package: "swift-io"),
            ]
        ),
        .testTarget(
            name: "AuraTests",
            dependencies: [
                .target(name: "Aura"),
                .target(name: "AuraTesting"),
            ]
        ),
    ]
)

for target: Target in package.targets {
    {
        var settings: [SwiftSetting] = $0 ?? []
        settings.append(.enableUpcomingFeature("ExistentialAny"))
        settings.append(.enableUpcomingFeature("MemberImportVisibility"))
        settings.append(.enableUpcomingFeature("InternalImportsByDefault"))
        settings.append(.enableExperimentalFeature("StrictConcurrency"))
        $0 = settings
    } (&target.swiftSettings)
}
