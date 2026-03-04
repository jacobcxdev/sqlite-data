// swift-tools-version: 6.1

import PackageDescription

let android = Context.environment["TARGET_OS_ANDROID"] ?? "0" != "0"

let package = Package(
  name: "sqlite-data",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v7),
  ],
  products: [
    .library(
      name: "SQLiteData",
      targets: ["SQLiteData"]
    ),
  ]
    + (android ? [] : [
      .library(
        name: "SQLiteDataTestSupport",
        targets: ["SQLiteDataTestSupport"]
      ),
    ]),
  traits: [
    .trait(
      name: "SQLiteDataTagged",
      description: "Introduce SQLiteData conformances to the swift-tagged package."
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", from: "1.0.0"),
    .package(path: "../GRDB.swift"),
    .package(path: "../swift-concurrency-extras"),
    .package(path: "../swift-custom-dump"),
    .package(path: "../swift-dependencies"),
    .package(path: "../swift-perception"),
    .package(path: "../swift-sharing"),
    .package(
      path: "../swift-structured-queries",
      traits: [
        .trait(name: "StructuredQueriesTagged", condition: .when(traits: ["SQLiteDataTagged"]))
      ]
    ),
    .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0"),
    .package(path: "../xctest-dynamic-overlay"),
  ]
    + (android
      ? [
          .package(url: "https://source.skip.tools/skip-bridge.git", "0.16.4"..<"2.0.0"),
          .package(path: "../skip-android-bridge"),
          .package(url: "https://source.skip.tools/swift-jni.git", "0.3.1"..<"2.0.0"),
        ]
      : [
          .package(path: "../swift-snapshot-testing"),
        ]),
  targets: [
    .target(
      name: "SQLiteData",
      dependencies: [
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "OrderedCollections", package: "swift-collections"),
        .product(name: "Perception", package: "swift-perception"),
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "StructuredQueriesSQLite", package: "swift-structured-queries"),
        .product(
          name: "Tagged",
          package: "swift-tagged",
          condition: .when(traits: ["SQLiteDataTagged"])
        ),
      ]
        + (android ? [
          .product(name: "SkipBridge", package: "skip-bridge"),
          .product(name: "SkipAndroidBridge", package: "skip-android-bridge"),
          .product(name: "SwiftJNI", package: "swift-jni"),
        ] : [])
    ),
  ]
    + (android ? [] : [
      .target(
        name: "SQLiteDataTestSupport",
        dependencies: [
          "SQLiteData",
          .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
          .product(name: "CustomDump", package: "swift-custom-dump"),
          .product(name: "Dependencies", package: "swift-dependencies"),
          .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
          .product(name: "StructuredQueriesTestSupport", package: "swift-structured-queries"),
        ]
      ),
      .testTarget(
        name: "SQLiteDataTests",
        dependencies: [
          "SQLiteData",
          "SQLiteDataTestSupport",
          .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
          .product(name: "InlineSnapshotTesting", package: "swift-snapshot-testing"),
          .product(name: "SnapshotTestingCustomDump", package: "swift-snapshot-testing"),
          .product(name: "StructuredQueries", package: "swift-structured-queries"),
        ]
      ),
    ]),
  swiftLanguageModes: [.v6]
)

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("MemberImportVisibility")
  // .unsafeFlags([
  //   "-Xfrontend",
  //   "-warn-long-function-bodies=50",
  //   "-Xfrontend",
  //   "-warn-long-expression-type-checking=50",
  // ])
]

for index in package.targets.indices {
  package.targets[index].swiftSettings = swiftSettings
}

#if !os(Windows)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
