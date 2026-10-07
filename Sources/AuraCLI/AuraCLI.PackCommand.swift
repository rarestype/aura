import ArgumentParser
import Aura
import SystemIO
import SystemPackage

extension AuraCLI {
    struct PackCommand: ParsableCommand {
        static var configuration: CommandConfiguration {
            .init(
                commandName: "pack",
                abstract: """
                Assembles surface textures, physical parameters, and optional .atmo atmosphere intermediates into a .aura archive
                """
            )
        }

        @Argument(
            help: """
            Directory containing surface cubemap faces (px.webp, nx.webp, py.webp, ny.webp, pz.webp, nz.webp)
            """
        ) var textures: String?

        @Option(
            name: .customLong("manifest"),
            help: "Path to an assembly manifest Ion file"
        ) var manifest: String?

        @Option(
            name: .customLong("name"),
            help: "Planet name (defaults to texture directory name)"
        ) var name: String?

        @Option(
            name: .customLong("atmosphere"),
            help: "Path to .atmo intermediate file"
        ) var atmosphere: String?

        @Option(
            name: .customLong("relief-scale"),
            help: "Relief elevation scale"
        ) var reliefScale: Double?

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
            help: "Destination .aura file path"
        ) var output: String?

        mutating func run() throws {
            // Mutual exclusion check
            if  self.manifest != nil && self.textures != nil {
                throw ValidationError("Positional textures and --manifest are mutually exclusive")
            }
            if  self.manifest == nil && self.textures == nil {
                throw ValidationError("Either positional textures or --manifest must be provided")
            }

            if  let manifestPathString: String = self.manifest {
                try self.runManifestMode(manifestPathString: manifestPathString)
            } else if let texturesPathString: String = self.textures {
                try self.runSingleBodyMode(texturesPathString: texturesPathString)
            }
        }

        private func runSingleBodyMode(texturesPathString: String) throws {
            let texturesDir: FilePath = .init(texturesPathString)
            let planetName: String = self.name ?? texturesDir.lastComponent?.string ?? "Planet"

            let albedo: PlanetaryArchive.CubemapFaces = try Self.loadAlbedo(
                texturesDir: texturesDir
            )
            let relief: PlanetaryArchive.CubemapFaces? = try Self.loadRelief(
                texturesDir: texturesDir
            )

            var atmosphereDescriptor: AtmosphereDescriptor? = nil
            if  let atmoString: String = self.atmosphere {
                let atmoPath: FilePath = .init(atmoString)
                guard (try? atmoPath.exists) == true else {
                    throw ValidationError("Atmosphere intermediate not found at '\(atmoString)'")
                }
                do {
                    let bytes: [UInt8] = try atmoPath.read([UInt8].self)
                    let atmoArchive: AtmosphereArchive = try .deserialize(from: bytes[...])
                    atmosphereDescriptor = atmoArchive.atmosphere
                } catch {
                    throw ValidationError("Atmosphere intermediate not found at '\(atmoString)'")
                }
            }

            guard let radius: Double = self.radius else {
                throw ValidationError("Planetary radius in kilometers must be specified via --radius")
            }

            let params: PlanetaryArchive.SurfaceParameters = .init(
                radius: radius,
                tilt: self.tilt ?? 0.0,
                flattening: self.flattening ?? 0.0,
                reliefScale: self.reliefScale ?? 1.0
            )

            let entry: PlanetaryArchive.PlanetEntry = .init(
                name: planetName,
                parameters: params,
                surface: .init(albedo: albedo, relief: relief),
                atmosphere: atmosphereDescriptor
            )

            let outPath: FilePath
            if  let output: String = self.output {
                outPath = .init(output)
            } else {
                let parentDir: FilePath = texturesDir.removingLastComponent()
                outPath = parentDir.appending("\(planetName).aura")
            }

            let parent: FilePath = outPath.removingLastComponent()
            if !parent.isEmpty {
                try FilePath.Directory.init(path: parent).create()
            }

            let archive: PlanetaryArchive = .init(planets: [entry])
            try archive.write(to: outPath)
            print("Successfully packed '\(planetName)' into '\(outPath)'!")
        }

        private func runManifestMode(manifestPathString: String) throws {
            let manifestPath: FilePath = .init(manifestPathString)
            guard (try? manifestPath.exists) == true else {
                throw ValidationError("Manifest file not found at '\(manifestPathString)'")
            }

            let manifest: PackagingManifest = try PackagingManifest.load(from: manifestPath)
            var manifestDir: FilePath = manifestPath.removingLastComponent()
            if  manifestDir.isEmpty {
                manifestDir = "."
            }

            var entries: [PlanetaryArchive.PlanetEntry] = []
            entries.reserveCapacity(manifest.planets.count)

            for planet: PackagingManifest.PlanetEntry in manifest.planets {
                let texturesPath: FilePath = Self.resolve(
                    pathString: planet.textures,
                    relativeTo: manifestDir
                )
                let albedo: PlanetaryArchive.CubemapFaces = try Self.loadAlbedo(
                    texturesDir: texturesPath
                )
                let relief: PlanetaryArchive.CubemapFaces? = try Self.loadRelief(
                    texturesDir: texturesPath
                )

                var atmosphereDescriptor: AtmosphereDescriptor? = nil
                if  let atmoRel: String = planet.atmosphere {
                    let atmoPath: FilePath = Self.resolve(
                        pathString: atmoRel,
                        relativeTo: manifestDir
                    )
                    guard (try? atmoPath.exists) == true else {
                        throw ValidationError("Atmosphere intermediate not found at '\(atmoRel)'")
                    }
                    do {
                        let bytes: [UInt8] = try atmoPath.read([UInt8].self)
                        let atmoArchive: AtmosphereArchive = try .deserialize(from: bytes[...])
                        atmosphereDescriptor = atmoArchive.atmosphere
                    } catch {
                        throw ValidationError("Atmosphere intermediate not found at '\(atmoRel)'")
                    }
                }

                let entry: PlanetaryArchive.PlanetEntry = .init(
                    name: planet.name,
                    parameters: planet.parameters,
                    surface: .init(albedo: albedo, relief: relief),
                    atmosphere: atmosphereDescriptor
                )
                entries.append(entry)
            }

            let outPath: FilePath = Self.resolve(
                pathString: manifest.output,
                relativeTo: manifestDir
            )
            let parent: FilePath = outPath.removingLastComponent()
            if !parent.isEmpty {
                try FilePath.Directory.init(path: parent).create()
            }

            let archive: PlanetaryArchive = .init(planets: entries)
            try archive.write(to: outPath)
            print("Successfully packed \(entries.count) bodies into '\(outPath)'!")
        }

        private static func loadAlbedo(
            texturesDir: FilePath
        ) throws -> PlanetaryArchive.CubemapFaces {
            let faceNames: [String] = [
                "px.webp",
                "nx.webp",
                "py.webp",
                "ny.webp",
                "pz.webp",
                "nz.webp"
            ]
            var missing: [String] = []
            var faces: [String: [UInt8]] = [:]

            for face: String in faceNames {
                let facePath: FilePath = texturesDir.appending(face)
                if  let bytes: [UInt8] = try? facePath.read([UInt8].self) {
                    faces[face] = bytes
                } else {
                    missing.append(face)
                }
            }

            if !missing.isEmpty {
                throw ValidationError(
                    "Missing required albedo faces in '\(texturesDir)': [\(missing.joined(separator: ", "))]"
                )
            }

            return .init(
                px: faces["px.webp"]!,
                nx: faces["nx.webp"]!,
                py: faces["py.webp"]!,
                ny: faces["ny.webp"]!,
                pz: faces["pz.webp"]!,
                nz: faces["nz.webp"]!
            )
        }

        private static func loadRelief(
            texturesDir: FilePath
        ) throws -> PlanetaryArchive.CubemapFaces? {
            let reliefDir: FilePath = texturesDir.appending("Relief")
            guard (try? reliefDir.exists) == true else {
                return nil
            }

            let faceNames: [String] = [
                "px.webp",
                "nx.webp",
                "py.webp",
                "ny.webp",
                "pz.webp",
                "nz.webp"
            ]
            var missing: [String] = []
            var faces: [String: [UInt8]] = [:]

            for face: String in faceNames {
                let facePath: FilePath = reliefDir.appending(face)
                if  let bytes: [UInt8] = try? facePath.read([UInt8].self) {
                    faces[face] = bytes
                } else {
                    missing.append(face)
                }
            }

            if !missing.isEmpty {
                throw ValidationError(
                    "Incomplete relief normal map in '\(reliefDir)': missing [\(missing.joined(separator: ", "))]"
                )
            }

            return .init(
                px: faces["px.webp"]!,
                nx: faces["nx.webp"]!,
                py: faces["py.webp"]!,
                ny: faces["ny.webp"]!,
                pz: faces["pz.webp"]!,
                nz: faces["nz.webp"]!
            )
        }

        private static func resolve(pathString: String, relativeTo base: FilePath) -> FilePath {
            let path: FilePath = .init(pathString)
            if  path.isAbsolute {
                return path
            }
            var combined: FilePath = base
            for comp: FilePath.Component in path.components {
                combined.append(comp)
            }
            combined.lexicallyNormalize()
            return combined
        }
    }
}
