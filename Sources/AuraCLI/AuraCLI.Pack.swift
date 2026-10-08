import ArgumentParser
import Aura
import Ion
import SystemIO
import SystemPackage

extension AuraCLI {
    struct Pack {
        @Argument(
            help: """
            Directory containing surface cubemap faces \
            (px.webp, nx.webp, py.webp, ny.webp, pz.webp, nz.webp)
            """
        ) var textures: FilePath.Directory?

        @Option(
            name: .customLong("manifest"),
            help: "Path to an assembly manifest Ion file"
        ) var manifest: FilePath?

        @Option(
            name: .customLong("name"),
            help: "Planet name (defaults to texture directory name)"
        ) var name: String?

        @Option(
            name: .customLong("atmosphere"),
            help: "Path to .atmo intermediate file"
        ) var atmosphere: FilePath?

        @Option(
            name: [.customLong("relief"), .customLong("relief-scale")],
            help: "Relief elevation scale"
        ) var relief: Double?

        @Option(
            name: .customLong("radius"),
            help: "Body radius in kilometers"
        ) var radius: Double?

        @Option(
            name: .customLong("tilt"),
            help: "Axial tilt in radians"
        ) var tilt: Double?

        @Option(
            name: .customLong("flattening"),
            help: "Geometric flattening"
        ) var flattening: Double?

        @Option(
            name: [.customLong("output"), .customShort("o")],
            help: "Destination .aura file path (relative to manifest, if provided)"
        ) var output: FilePath?
    }
}
extension AuraCLI.Pack: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "pack",
            abstract: """
            Assembles surface textures, physical parameters, and optional .atmo \
            atmosphere intermediates into a .aura archive
            """
        )
    }

    mutating func run() throws {
        switch (manifest: self.manifest, textures: self.textures) {
        case (_?, _?):
            throw ValidationError.init(
                "Positional textures and --manifest are mutually exclusive"
            )
        case (nil, nil):
            throw ValidationError.init(
                "Either positional textures or --manifest must be provided"
            )
        case (manifest: let manifest?, nil):
            try self.run(manifest: manifest)

        case (nil, textures: let textures?):
            try self.run(textures: textures)
        }
    }
}
extension AuraCLI.Pack {
    private func run(textures: FilePath.Directory) throws {
        guard
        let radius: Double = self.radius else {
            throw ValidationError.init(
                "Planetary radius in kilometers must be specified via --radius"
            )
        }

        let output: FilePath
        let name: String

        if  let last: String = textures.components.last?.string,
            let parent: FilePath.Directory = textures.parent {
            name = self.name ?? last
            output = self.output ?? parent / "\(name).aura"
        } else {
            throw ValidationError.init(
                "Textures directory cannot be file system root"
            )
        }

        let albedo: AuraArchive.Cubemap = try .load(required: textures)
        let relief: AuraArchive.Cubemap? = try .load(optional: textures / Self.Relief)

        let atmosphere: Atmosphere?
        if  let path: FilePath = self.atmosphere {
            let file: Ion = .init(bytes: try path.read()[...])
            let archive: AtmosphereArchive = try file.decode()

            atmosphere = archive.atmosphere
        } else {
            atmosphere = nil
        }

        let entry: AuraArchive.Body = .init(
            name: name,
            spheroid: .init(
                radius: radius,
                relief: self.relief ?? 1,
                tilt: self.tilt ?? 0,
                flattening: self.flattening ?? 0
            ),
            albedo: albedo,
            relief: relief,
            atmosphere: atmosphere
        )

        //  if not using specific output path, we can assume the directory already exists
        if  let path: FilePath.Directory = self.output?.parent {
            try path.create()
        }

        let archive: AuraArchive = .init(bodies: [entry])
        try archive.write(to: output)

        print("Successfully packed '\(name)' into '\(output)'!")
    }

    private func run(manifest path: FilePath) throws {
        let manifest: PackagingManifest = try .load(from: path)
        let origin: FilePath.Directory = path.parent ?? "."
        let output: FilePath

        if  let specified: FilePath = self.output {
            output = specified.isAbsolute ? specified : origin / specified.components
        } else {
            output = origin / "SolarSystem.aura"
        }

        let entries: [AuraArchive.Body] = try manifest.bodies.map {
            let textures: FilePath.Directory = .init($0.textures)
            let resolved: FilePath.Directory = textures.path.isAbsolute
                ? textures
                : origin / textures.components

            let albedo: AuraArchive.Cubemap = try .load(required: resolved)
            let relief: AuraArchive.Cubemap? = try .load(optional: resolved / Self.Relief)

            let atmosphere: Atmosphere?
            if  let path: FilePath = $0.atmosphere.map(FilePath.init(_:)) {
                let path: FilePath = path.isAbsolute
                    ? path
                    : origin / path.components

                let file: Ion = .init(bytes: try path.read()[...])
                let archive: AtmosphereArchive = try file.decode()

                atmosphere = archive.atmosphere
            } else {
                atmosphere = nil
            }

            return .init(
                name: $0.name,
                spheroid: $0.spheroid,
                albedo: albedo,
                relief: relief,
                atmosphere: atmosphere
            )
        }

        if  let path: FilePath.Directory = self.output?.parent {
            try path.create()
        }

        let archive: AuraArchive = .init(bodies: entries)
        try archive.write(to: output)

        print("Successfully packed \(entries.count) bodies into '\(output)'!")
    }
}
extension AuraCLI.Pack {
    private static var Relief: FilePath.Component { "Relief" }
}
