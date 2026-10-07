import Aura
import AuraDecoding
import AuraEncoding
import Ion
import Testing

@Suite struct AuraTests {
    @Test static func IonBinaryRoundtrip() throws {
        let config: AtmosphereConfig = .earth
        let ion: Ion = .encode(atomic: config)
        let decoded: AtmosphereConfig = try ion.decode(atomic: AtmosphereConfig.self)

        #expect(decoded.name == "Earth")
        #expect(decoded.radius_bottom == config.radius_bottom)
        #expect(decoded.radius_top == config.radius_top)
        #expect(decoded.rayleigh_scattering == config.rayleigh_scattering)
        #expect(decoded.mie_scattering == config.mie_scattering)
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

        let compressed: [UInt8] = TableEncoder.compress(
            simd4: data,
            count: (x: width, y: height, z: depth)
        )

        #expect(compressed.count < data.count * MemoryLayout<SIMD4<Float>>.size)

        let descriptor: AtmosphereDescriptor.TableDescriptor = .init(
            x: width,
            y: height,
            z: depth,
            bytes: compressed
        )
        let decompressed: [SIMD4<Float>] = try descriptor.decompress()

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

        let compressed: [UInt8] = TableEncoder.compress(
            simd4: data,
            count: (x: width, y: height, z: 1)
        )

        let descriptor: AtmosphereDescriptor.TableDescriptor = .init(
            x: width,
            y: height,
            z: 1,
            bytes: compressed
        )
        let decompressed: [SIMD4<Float>] = try descriptor.decompress()

        #expect(decompressed.count == data.count)
        #expect(decompressed == data)
    }

    @Test static func TableDecoderDirect() throws {
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

        let encoded: [UInt8] = TableEncoder.encode(
            simd4: data,
            count: (x: width, y: height, z: depth)
        )

        let decoded: [SIMD4<Float>] = TableDecoder.decode(
            bytes: encoded,
            count: (x: width, y: height, z: depth)
        )

        #expect(decoded == data)
    }

    @Test static func AtmosphereArchiveSinglePlanetRoundtrip() async throws {
        let earthConfig: AtmosphereConfig = .earth
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
            let texels: Int = desc.x * desc.y * desc.z
            totalRawBytes += texels * MemoryLayout<SIMD4<Float>>.stride
        }

        let ion: Ion = .encode(atomic: archive)
        #expect(ion.bytes.count > 0)
        #expect(ion.bytes.count < totalRawBytes)

        let deserialized: AtmosphereArchive = try .deserialize(from: ion.bytes)
        #expect(deserialized.version == AtmosphereArchive.currentVersion)
        #expect(deserialized.name == "Earth")

        #expect(deserialized.atmosphere.parameters.radius_bottom == 6360000.0)

        let transmittanceDescriptor: AtmosphereDescriptor.TableDescriptor = deserialized.atmosphere.tables.transmittance
        let transmittance: [SIMD4<Float>] = try transmittanceDescriptor.decompress()
        #expect(
            transmittance.count == transmittanceDescriptor.x * transmittanceDescriptor.y
        )

        let scatteringDescriptor: AtmosphereDescriptor.TableDescriptor = deserialized.atmosphere.tables.scattering
        let scattering: [SIMD4<Float>] = try scatteringDescriptor.decompress()
        #expect(
            scattering.count == scatteringDescriptor.x * scatteringDescriptor.y * scatteringDescriptor.z
        )

        let irradianceDescriptor: AtmosphereDescriptor.TableDescriptor = deserialized.atmosphere.tables.irradiance
        let irradiance: [SIMD4<Float>] = try irradianceDescriptor.decompress()
        #expect(irradiance.count == irradianceDescriptor.x * irradianceDescriptor.y)
    }

    @Test static func AtmosphereArchiveMultiPlanetBake() async throws {
        let earthConfig: AtmosphereConfig = .earth
        let marsConfig: AtmosphereConfig = .mars
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

        let earthConfig: AtmosphereConfig = .earth
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

    @Test static func SurfaceParametersMissingRadiusThrows() throws {
        struct IncompleteParameters: IonEncodableStruct {
            enum CodingKey: String, IonSymbolizable {
                case tilt
                case flattening
                case relief_scale
            }
            func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
                ion[.tilt] = 0.0
                ion[.flattening] = 0.0
                ion[.relief_scale] = 1.0
            }
        }
        let ion: Ion = .encode(atomic: IncompleteParameters())
        #expect(throws: (any Error).self) {
            try ion.decode(atomic: PlanetaryArchive.SurfaceParameters.self)
        }
    }

    @Test static func TableDecompressionThrowsOnCorrupt() throws {
        let corrupt: [UInt8] = [0x01, 0x02, 0x03, 0x04]
        let descriptor: AtmosphereDescriptor.TableDescriptor = .init(
            x: 16,
            y: 16,
            z: 1,
            bytes: corrupt
        )
        #expect(throws: (any Error).self) {
            _ = try descriptor.decompress()
        }
    }
}

extension AtmosphereConfig {
    static var earth: Self {
        .init(
            name: "Earth",
            radius_bottom: 6360000.0,
            radius_top: 6420000.0,
            sun_angular_radius: 0.004675,
            max_sun_zenith_angle: 102.0,
            rayleigh_scale_height: 8000.0,
            rayleigh_scattering: [
                5.8023393817123834e-06,
                1.3557762447920223e-05,
                3.3100005976367735e-05
            ],
            mie_scale_height: 1200.0,
            mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
            mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
            mie_albedo: 0.9,
            mie_g: 0.8,
            ozone_extinction: [7.206534e-07, 1.7710017e-06, 6.5216177e-08],
            ozone_altitude: 25000.0,
            ozone_thickness: 15000.0,
            solar_irradiance: [1.49265, 1.850945, 1.7622550000000001],
            ground_albedo: [0.1, 0.1, 0.1]
        )
    }

    static var mars: Self {
        .init(
            name: "Mars",
            radius_bottom: 3389500.0,
            radius_top: 3450000.0,
            sun_angular_radius: 0.003067,
            max_sun_zenith_angle: 100.0,
            rayleigh_scale_height: 11100.0,
            rayleigh_scattering: [1.9e-07, 4.5e-07, 1.1e-06],
            mie_scale_height: 2000.0,
            mie_scattering: [4.0e-06, 3.2e-06, 2.0e-06],
            mie_extinction: [4.5e-06, 3.8e-06, 2.8e-06],
            mie_albedo: 0.85,
            mie_g: 0.7,
            solar_irradiance: [0.642, 0.796, 0.758],
            ground_albedo: [0.25, 0.15, 0.1]
        )
    }
}
