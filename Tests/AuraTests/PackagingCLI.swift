import Aura
import AuraDecoding
import Ion
import SystemIO
import SystemPackage
import Testing

@Suite struct PackagingCLI {
    @Test static func EndToEndAssembly() async throws {
        let tempDir: FilePath = .init("/tmp/AuraTest_\(UInt64.random(in: 0 ... .max))")
        try FilePath.Directory.init(path: tempDir).create()

        let earthDir: FilePath = tempDir.appending("Public").appending("Earth")
        let moonDir: FilePath = tempDir.appending("Public").appending("The Moon")
        let atmoDir: FilePath = tempDir.appending(".build").appending("atmospheres")
        let manifestsDir: FilePath = tempDir.appending("World").appending("Planetarium")

        try FilePath.Directory.init(path: earthDir.appending("Relief")).create()
        try FilePath.Directory.init(path: moonDir).create()
        try FilePath.Directory.init(path: atmoDir).create()
        try FilePath.Directory.init(path: manifestsDir).create()

        // Create dummy webp face bytes
        let dummyAlbedoBytes: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x01, 0x02, 0x03, 0x04]
        let dummyReliefBytes: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x05, 0x06, 0x07, 0x08]
        let faces: [String] = ["px.webp", "nx.webp", "py.webp", "ny.webp", "pz.webp", "nz.webp"]

        for face: String in faces {
            let earthAlbedoPath: FilePath = earthDir.appending(face)
            try earthAlbedoPath.overwrite(with: dummyAlbedoBytes[...])

            let earthReliefPath: FilePath = earthDir.appending("Relief").appending(face)
            try earthReliefPath.overwrite(with: dummyReliefBytes[...])

            let moonAlbedoPath: FilePath = moonDir.appending(face)
            try moonAlbedoPath.overwrite(with: dummyAlbedoBytes[...])
        }

        // Bake Earth atmosphere to .atmo
        let earthConfig: AtmosphereConfig = try .parse(ion: AuraTests.earth)
        let earthAtmo: AtmosphereArchive = try await .bake(
            config: earthConfig,
            workers: 4,
            detail: 1
        )
        let earthAtmoPath: FilePath = atmoDir.appending("Earth.atmo")
        try earthAtmo.write(to: earthAtmoPath)

        // Create manifest.ion
        let manifestContent: String = """
        {
            version: 1,
            output: "../../Public/Earth-Moon.aura",
            planets: [
                {
                    name: "Earth",
                    textures: "../../Public/Earth",
                    atmosphere: "../../.build/atmospheres/Earth.atmo",
                    parameters: {
                        radius: 6371.0e0,
                        tilt: 0.4084e0,
                        flattening: 0.00335e0,
                        relief_scale: 1.0e0
                    }
                },
                {
                    name: "The Moon",
                    textures: "../../Public/The Moon",
                    parameters: {
                        radius: 1737.4e0,
                        tilt: 0.0269e0,
                        flattening: 0.0e0,
                        relief_scale: 1.5e0
                    }
                }
            ]
        }
        """
        let manifestPath: FilePath = manifestsDir.appending("earth_moon.ion")
        try manifestPath.overwrite(with: manifestContent.utf8)

        // Load manifest
        let manifest: PackagingManifest = try PackagingManifest.load(from: manifestPath)
        #expect(manifest.planets.count == 2)

        // Assemble PlanetaryArchive
        var entries: [PlanetaryArchive.PlanetEntry] = []
        for planet: PackagingManifest.PlanetEntry in manifest.planets {
            let texturesPath: FilePath = tempDir.appending("Public").appending(planet.name)
            var albedoMap: [String: [UInt8]] = [:]
            for face: String in faces {
                let faceBytes: [UInt8] = try texturesPath.appending(face).read([UInt8].self)
                albedoMap[face] = faceBytes
            }
            let albedo: PlanetaryArchive.CubemapFaces = .init(
                px: albedoMap["px.webp"]!,
                nx: albedoMap["nx.webp"]!,
                py: albedoMap["py.webp"]!,
                ny: albedoMap["ny.webp"]!,
                pz: albedoMap["pz.webp"]!,
                nz: albedoMap["nz.webp"]!
            )

            var relief: PlanetaryArchive.CubemapFaces? = nil
            let reliefDir: FilePath = texturesPath.appending("Relief")
            if (try? reliefDir.exists) == true {
                var reliefMap: [String: [UInt8]] = [:]
                for face: String in faces {
                    let faceBytes: [UInt8] = try reliefDir.appending(face).read([UInt8].self)
                    reliefMap[face] = faceBytes
                }
                relief = .init(
                    px: reliefMap["px.webp"]!,
                    nx: reliefMap["nx.webp"]!,
                    py: reliefMap["py.webp"]!,
                    ny: reliefMap["ny.webp"]!,
                    pz: reliefMap["pz.webp"]!,
                    nz: reliefMap["nz.webp"]!
                )
            }

            var atmoDesc: AtmosphereDescriptor? = nil
            if planet.atmosphere != nil {
                let atmoBytes: [UInt8] = try earthAtmoPath.read([UInt8].self)
                let atmoArchive: AtmosphereArchive = try .deserialize(from: atmoBytes)
                atmoDesc = atmoArchive.atmosphere
            }

            entries.append(
                .init(
                    name: planet.name,
                    parameters: planet.parameters,
                    surface: .init(albedo: albedo, relief: relief),
                    atmosphere: atmoDesc
                )
            )
        }

        let archive: PlanetaryArchive = .init(planets: entries)
        let auraPath: FilePath = tempDir.appending("Public").appending("Earth-Moon.aura")
        try archive.write(to: auraPath)

        let auraBytes: [UInt8] = try auraPath.read([UInt8].self)
        let loadedArchive: PlanetaryArchive = try .deserialize(from: auraBytes)
        #expect(loadedArchive.version == 2)
        #expect(loadedArchive.planets.count == 2)

        let loadedEarth: PlanetaryArchive.PlanetEntry = try #require(loadedArchive["Earth"])
        #expect(loadedEarth.parameters.radius == 6371.0)
        #expect(loadedEarth.surface.albedo.px == dummyAlbedoBytes)
        #expect(loadedEarth.surface.relief?.pz == dummyReliefBytes)
        #expect(loadedEarth.atmosphere?.parameters.radius_bottom == 6360000.0)

        let loadedMoon: PlanetaryArchive.PlanetEntry = try #require(loadedArchive["The Moon"])
        #expect(loadedMoon.parameters.radius == 1737.4)
        #expect(loadedMoon.surface.relief == nil)
        #expect(loadedMoon.atmosphere == nil)

        // Cleanup
        _ = try? tempDir.remove(force: true)
    }
}
