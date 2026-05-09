import ProjectDescription

let project = Project(
    name: "DarkRoom",
    organizationName: "DarkRoom",
    options: .options(
        automaticSchemesOptions: .enabled(),
        defaultKnownRegions: ["en"],
        developmentRegion: "en"
    ),
    settings: .settings(base: [
        "MACOSX_DEPLOYMENT_TARGET": "14.0",
        "SWIFT_VERSION": "6.0"
    ]),
    targets: [
        .target(
            name: "DarkRoom",
            destinations: .macOS,
            product: .app,
            bundleId: "dev.darkroom.app",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "DarkRoom",
                "LSApplicationCategoryType": "public.app-category.photography",
                "NSPhotoLibraryUsageDescription": "DarkRoom reads selected local image folders for non-destructive photo grading."
            ]),
            sources: ["apps/macos/Sources/**"],
            resources: ["apps/macos/Resources/**"]
        ),
        .target(
            name: "DarkRoomTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "dev.darkroom.tests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["apps/macos/Tests/**"],
            dependencies: [.target(name: "DarkRoom")]
        )
    ]
)
