@testable import Aura
import AuraDecoding
import Ion
import Testing

@Suite struct AuraTests {
    @Test static func EarthParametersMatch() throws {
        let resolutions: (
            transmittance: Vector2<Int>,
            scattering: Vector4<Int>,
            irradiance: Vector2<Int>
        ) = (
            transmittance: Vector2<Int>.init(32, 8)       &<< 1,
            scattering: Vector4<Int>.init(4, 16, 4, 1) &<< 1,
            irradiance: Vector2<Int>.init(8, 2)        &<< 1
        )
        let reference: Atmosphere = .earth(resolutions: resolutions)
        let config: AtmosphereConfig = try .parse(ion: Self.earth)
        let parameterized: Atmosphere = .from(config: config, resolutions: resolutions)

        #expect(reference.radius == parameterized.radius)
        #expect(reference.rayleigh.scattering == parameterized.rayleigh.scattering)
        #expect(reference.mie.scattering == parameterized.mie.scattering)
        #expect(reference.mie.extinction == parameterized.mie.extinction)
        #expect(reference.mie.g == parameterized.mie.g)
        #expect(reference.irradiance == parameterized.irradiance)
        #expect(reference.ground == parameterized.ground)
        #expect(reference.μsmin == parameterized.μsmin)
        #expect(reference.absorption.extinction == parameterized.absorption.extinction)
    }

    @Test static func IonBinaryRoundtrip() throws {
        let config: AtmosphereConfig = try .parse(ion: Self.earth)
        let ion: Ion = .encode(atomic: config)
        let decoded: AtmosphereConfig = try ion.decode(atomic: AtmosphereConfig.self)

        #expect(decoded.name == "Earth")
        #expect(decoded.radius_bottom == config.radius_bottom)
        #expect(decoded.radius_top == config.radius_top)
        #expect(decoded.rayleigh_scattering == config.rayleigh_scattering)
        #expect(decoded.mie_scattering == config.mie_scattering)
    }

    @Test static func IonTextParsing() throws {
        let config: AtmosphereConfig = try .parse(ion: Self.earth)
        #expect(config.name == "Earth")
        #expect(config.radius_bottom == 6360000.0)
        #expect(config.mie_g == 0.8)
    }


    @Test static func AtmosphereCompressionRoundtrip() throws {
        // Create synthetic 3D volume with smooth gradients (like scattering table)
        let width: Int = 32
        let height: Int = 16
        let depth: Int = 4
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(width * height * depth)

        for z: Int in 0 ..< depth {
            for y: Int in 0 ..< height {
                for x: Int in 0 ..< width {
                    let fx: Float = Float(x) / Float(width)
                    let fy: Float = Float(y) / Float(height)
                    let fz: Float = Float(z) / Float(depth)
                    data.append(.init(fx * 1.5, fy * 2.0, fz * 0.8, (fx + fy) * 0.2))
                }
            }
        }

        let compressed: [UInt8] = TableCompression.compress(
            simd4: data,
            width: width,
            height: height,
            depth: depth
        )

        #expect(compressed.count < data.count * MemoryLayout<SIMD4<Float>>.size)

        let decompressed: [SIMD4<Float>] = try TableCompression.decompress(
            archive: compressed,
            width: width,
            height: height,
            depth: depth
        )

        #expect(decompressed.count == data.count)
        #expect(decompressed == data)
    }

    @Test static func TableCompression2DRoundtrip() throws {
        // Test 2D table (e.g. transmittance / irradiance)
        let width: Int = 64
        let height: Int = 16
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(width * height)

        for y: Int in 0 ..< height {
            for x: Int in 0 ..< width {
                let fx: Float = Float(x) / Float(width)
                let fy: Float = Float(y) / Float(height)
                data.append(.init(fx * 1.5, fy * 2.0, (fx + fy) * 0.5, 1.0))
            }
        }

        let compressed: [UInt8] = TableCompression.compress(
            simd4: data,
            width: width,
            height: height,
            depth: 1
        )

        let decompressed: [SIMD4<Float>] = try TableCompression.decompress(
            archive: compressed,
            width: width,
            height: height,
            depth: 1
        )

        #expect(decompressed.count == data.count)
        #expect(decompressed == data)
    }

    @Test static func AtmosphereTableDecoderDirect() throws {
        let width: Int = 16
        let height: Int = 8
        let depth: Int = 2
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(width * height * depth)
        for z: Int in 0 ..< depth {
            for y: Int in 0 ..< height {
                for x: Int in 0 ..< width {
                    data.append(.init(Float(x), Float(y), Float(z), Float(x + y + z)))
                }
            }
        }

        let shuffled: [UInt8] = TableCompression.filterAndShuffle(
            simd4: data,
            width: width,
            height: height,
            depth: depth
        )

        let decoded: [SIMD4<Float>] = AtmosphereTableDecoder.decode(
            shuffled: shuffled,
            width: width,
            height: height,
            depth: depth
        )

        #expect(decoded == data)

        var inoutDecoded: [SIMD4<Float>] = .init(
            repeating: .zero,
            count: width * height * depth
        )
        AtmosphereTableDecoder.decode(
            shuffled: shuffled,
            into: &inoutDecoded,
            width: width,
            height: height,
            depth: depth
        )
        #expect(inoutDecoded == data)

        var rawBytesDecoded: [UInt8] = .init(repeating: 0, count: width * height * depth * 16)
        AtmosphereTableDecoder.decode(
            shuffled: shuffled,
            into: &rawBytesDecoded,
            width: width,
            height: height,
            depth: depth,
            bpp: 16
        )
        let rawMatches: Bool = data.withUnsafeBytes { rawData in
            rawBytesDecoded == Array(rawData)
        }
        #expect(rawMatches)
    }

    @Test static func AtmosphereArchiveSinglePlanetRoundtrip() async throws {
        let earthConfig: AtmosphereConfig = try .parse(ion: Self.earth)
        let archive: AtmosphereArchive = try await .bake(
            config: earthConfig,
            workers: 4,
            detail: 1
        )
        #expect(archive.name == "Earth")

        let tables: [AtmosphereDescriptor.TableDescriptor] = [
            archive.atmosphere.tables.transmittance,
            archive.atmosphere.tables.scattering,
            archive.atmosphere.tables.irradiance,
        ]
        var totalRawBytes: Int = 0
        for desc: AtmosphereDescriptor.TableDescriptor in tables {
            let texels: Int = desc.width * desc.height * (desc.depth ?? 1)
            totalRawBytes += texels * MemoryLayout<SIMD4<Float>>.stride
        }

        let archiveBytes: [UInt8] = try archive.serialize()
        #expect(archiveBytes.count > 0)
        #expect(archiveBytes.count < totalRawBytes)

        let deserialized: AtmosphereArchive = try .deserialize(from: archiveBytes)
        #expect(deserialized.version == AtmosphereArchive.currentVersion)
        #expect(deserialized.name == "Earth")

        #expect(deserialized.atmosphere.parameters.radius_bottom == 6360000.0)

        let transmittanceDescriptor: AtmosphereDescriptor.TableDescriptor = deserialized.atmosphere.tables.transmittance
        let transmittance: [SIMD4<Float>] = try transmittanceDescriptor.decode()
        #expect(
            transmittance.count == transmittanceDescriptor.width * transmittanceDescriptor.height
        )

        let scatteringDescriptor: AtmosphereDescriptor.TableDescriptor = deserialized.atmosphere.tables.scattering
        let scattering: [SIMD4<Float>] = try scatteringDescriptor.decode()
        #expect(
            scattering.count == scatteringDescriptor.width * scatteringDescriptor.height * (
                scatteringDescriptor.depth ?? 1
            )
        )

        let irradianceDescriptor: AtmosphereDescriptor.TableDescriptor = deserialized.atmosphere.tables.irradiance
        let irradiance: [SIMD4<Float>] = try irradianceDescriptor.decode()
        #expect(irradiance.count == irradianceDescriptor.width * irradianceDescriptor.height)
    }

    @Test static func AtmosphereArchiveMultiPlanetBake() async throws {
        let earthConfig: AtmosphereConfig = try .parse(ion: Self.earth)
        let marsConfig: AtmosphereConfig = try .parse(ion: Self.mars)
        let archives: [AtmosphereArchive] = try await AtmosphereArchive.bake(
            configs: [earthConfig, marsConfig],
            workers: 4,
            detail: 1
        )
        #expect(archives.count == 2)
        #expect(archives[0].name == "Earth")
        #expect(archives[1].name == "Mars")
        #expect(archives[0].atmosphere.parameters.radius_bottom == 6360000.0)
        #expect(archives[1].atmosphere.parameters.radius_bottom == 3389500.0)
    }

    @Test static func PlanetaryArchiveRoundtrip() async throws {
        let dummyFace: [UInt8] = [
            0x52,
            0x49,
            0x46,
            0x46,
            0x00,
            0x00,
            0x00,
            0x00
        ] // synthetic webp header
        let dummyAlbedo: PlanetaryArchive.CubemapFaces = .init(
            px: dummyFace,
            nx: dummyFace,
            py: dummyFace,
            ny: dummyFace,
            pz: dummyFace,
            nz: dummyFace
        )
        let dummyRelief: PlanetaryArchive.CubemapFaces = .init(
            px: dummyFace,
            nx: dummyFace,
            py: dummyFace,
            ny: dummyFace,
            pz: dummyFace,
            nz: dummyFace
        )

        let earthConfig: AtmosphereConfig = try .parse(ion: Self.earth)
        let earthAtmo: AtmosphereArchive = try await .bake(
            config: earthConfig,
            workers: 4,
            detail: 1
        )

        let earthEntry: PlanetaryArchive.PlanetEntry = .init(
            name: "Earth",
            parameters: .init(
                radius: 6371.0,
                tilt: 0.4084,
                flattening: 0.00335,
                reliefScale: 1.0
            ),
            surface: .init(albedo: dummyAlbedo, relief: dummyRelief),
            atmosphere: earthAtmo.atmosphere
        )

        let moonEntry: PlanetaryArchive.PlanetEntry = .init(
            name: "The Moon",
            parameters: .init(
                radius: 1737.4,
                tilt: 0.0269,
                flattening: 0.0,
                reliefScale: 1.5
            ),
            surface: .init(albedo: dummyAlbedo, relief: nil),
            atmosphere: nil
        )

        let archive: PlanetaryArchive = .init(planets: [earthEntry, moonEntry])
        let bytes: [UInt8] = try archive.serialize()
        #expect(!bytes.isEmpty)

        let deserialized: PlanetaryArchive = try .deserialize(from: bytes)
        #expect(deserialized.version == PlanetaryArchive.currentVersion)
        #expect(deserialized.planets.count == 2)

        let roundtripEarth: PlanetaryArchive.PlanetEntry = try #require(deserialized["Earth"])
        #expect(roundtripEarth.parameters.radius == 6371.0)
        #expect(roundtripEarth.parameters.tilt == 0.4084)
        #expect(roundtripEarth.surface.albedo.px == dummyFace)
        #expect(roundtripEarth.surface.relief?.pz == dummyFace)
        #expect(roundtripEarth.atmosphere != nil)
        #expect(roundtripEarth.atmosphere?.parameters.radius_bottom == 6360000.0)

        let roundtripMoon: PlanetaryArchive.PlanetEntry = try #require(deserialized["The Moon"])
        #expect(roundtripMoon.parameters.radius == 1737.4)
        #expect(roundtripMoon.parameters.reliefScale == 1.5)
        #expect(roundtripMoon.surface.relief == nil)
        #expect(roundtripMoon.atmosphere == nil)
    }

    @Test static func PackagingManifestParsing() throws {
        let manifestIon: String = """
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
        let ion: Ion = try .parse(atomic: manifestIon)
        let manifest: PackagingManifest = try ion.decode(atomic: PackagingManifest.self)
        #expect(manifest.version == 1)
        #expect(manifest.output == "../../Public/Earth-Moon.aura")
        #expect(manifest.planets.count == 2)
        #expect(manifest.planets[0].name == "Earth")
        #expect(manifest.planets[0].atmosphere == "../../.build/atmospheres/Earth.atmo")
        #expect(manifest.planets[0].parameters.radius == 6371.0)
        #expect(manifest.planets[1].name == "The Moon")
        #expect(manifest.planets[1].atmosphere == nil)
        #expect(manifest.planets[1].parameters.radius == 1737.4)
    }

    @Test static func ManifestMissingRadiusThrows() throws {
        let badParametersIon: String = """
        {
            tilt: 0.0e0,
            flattening: 0.0e0,
            relief_scale: 1.0e0
        }
        """
        let ion: Ion = try .parse(atomic: badParametersIon)
        #expect(throws: (any Error).self) {
            try ion.decode(atomic: PlanetaryArchive.SurfaceParameters.self)
        }
    }

    @Test static func TableCompressionThrowsOnCorrupt() throws {
        let corrupt: [UInt8] = [0x01, 0x02, 0x03, 0x04]
        #expect(throws: (any Error).self) {
            let _: [UInt8] = try TableCompression.decompress(
                archive: corrupt,
                width: 16,
                height: 16,
                depth: 1,
                bpp: 16
            )
        }
    }
}

extension AuraTests {
    static var earth: String {
        """
        {
            name: "Earth",
            radius_bottom: 6360000.0e0,
            radius_top: 6420000.0e0,
            sun_angular_radius: 0.004675e0,
            max_sun_zenith_angle: 102.0e0,
            rayleigh_scale_height: 8000.0e0,
            rayleigh_scattering: [
                5.8023393817123834e-06,
                1.3557762447920223e-05,
                3.3100005976367735e-05
            ],
            mie_scale_height: 1200.0e0,
            mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
            mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
            mie_albedo: 0.9e0,
            mie_g: 0.8e0,
            ozone_extinction: [7.206534e-07, 1.7710017e-06, 6.5216177e-08],
            ozone_altitude: 25000.0e0,
            ozone_thickness: 15000.0e0,
            solar_irradiance: [1.49265e0, 1.850945e0, 1.7622550000000001e0],
            ground_albedo: [0.1e0, 0.1e0, 0.1e0]
        }
        """
    }

    static var mars: String {
        """
        {
            name: "Mars",
            radius_bottom: 3389500.0e0,
            radius_top: 3450000.0e0,
            sun_angular_radius: 0.003067e0,
            max_sun_zenith_angle: 100.0e0,
            rayleigh_scale_height: 11100.0e0,
            rayleigh_scattering: [1.9e-07, 4.5e-07, 1.1e-06],
            mie_scale_height: 2000.0e0,
            mie_scattering: [4.0e-06, 3.2e-06, 2.0e-06],
            mie_extinction: [4.5e-06, 3.8e-06, 2.8e-06],
            mie_albedo: 0.85e0,
            mie_g: 0.7e0,
            solar_irradiance: [0.642e0, 0.796e0, 0.758e0],
            ground_albedo: [0.25e0, 0.15e0, 0.1e0]
        }
        """
    }
}
