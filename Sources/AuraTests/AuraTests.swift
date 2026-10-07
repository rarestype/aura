import Aura
import AuraDecoding
import AuraEncoding
import AuraTesting
import Ion
import Testing

@Suite struct AuraTests {
    @Test static func IonBinaryRoundtrip() throws {
        let config: AtmosphereConfiguration = .earth
        let ion: Ion = .encode(atomic: config)
        let decoded: AtmosphereConfiguration = try ion.decode()

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

        let descriptor: Atmosphere.Table = .init(
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

        let descriptor: Atmosphere.Table = .init(
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
        let archive: AtmosphereArchive = await .bake(.earth, detail: 1, workers: 4)
        #expect(archive.name == "Earth")

        let tables: [Atmosphere.Table] = [
            archive.atmosphere.transmittance,
            archive.atmosphere.scattering,
            archive.atmosphere.irradiance,
        ]
        var totalRawBytes: Int = 0
        for desc: Atmosphere.Table in tables {
            let texels: Int = desc.x * desc.y * desc.z
            totalRawBytes += texels * MemoryLayout<SIMD4<Float>>.stride
        }

        let ion: Ion = .encode(atomic: archive)
        #expect(ion.bytes.count > 0)
        #expect(ion.bytes.count < totalRawBytes)

        let deserialized: AtmosphereArchive = try ion.decode()
        #expect(deserialized.name == "Earth")

        #expect(deserialized.atmosphere.parameters.radius_bottom == 6360000.0)

        let transmittanceDescriptor: Atmosphere.Table = deserialized.atmosphere.transmittance
        let transmittance: [SIMD4<Float>] = try transmittanceDescriptor.decompress()
        #expect(
            transmittance.count == transmittanceDescriptor.x * transmittanceDescriptor.y
        )

        let scatteringDescriptor: Atmosphere.Table = deserialized.atmosphere.scattering
        let scattering: [SIMD4<Float>] = try scatteringDescriptor.decompress()
        #expect(
            scattering.count == scatteringDescriptor.x * scatteringDescriptor.y * scatteringDescriptor.z
        )

        let irradianceDescriptor: Atmosphere.Table = deserialized.atmosphere.irradiance
        let irradiance: [SIMD4<Float>] = try irradianceDescriptor.decompress()
        #expect(irradiance.count == irradianceDescriptor.x * irradianceDescriptor.y)
    }

    @Test static func AtmosphereArchiveMultiPlanetBake() async throws {
        let earth: AtmosphereConfiguration = .earth
        let mars: AtmosphereConfiguration = .mars
        let archives: [AtmosphereArchive] = await AtmosphereArchive.bake(
            bodies: [earth, mars],
            detail: 1,
            workers: 4,
        )
        #expect(archives.count == 2)
        #expect(archives[0].name == "Earth")
        #expect(archives[1].name == "Mars")
        #expect(archives[0].atmosphere.parameters.radius_bottom == 6360000.0)
        #expect(archives[1].atmosphere.parameters.radius_bottom == 3389500.0)
    }

    @Test static func AuraArchiveRoundtrip() async throws {
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
        let dummyAlbedo: AuraArchive.Cubemap = .init(
            px: dummyFace,
            nx: dummyFace,
            py: dummyFace,
            ny: dummyFace,
            pz: dummyFace,
            nz: dummyFace
        )
        let dummyRelief: AuraArchive.Cubemap = .init(
            px: dummyFace,
            nx: dummyFace,
            py: dummyFace,
            ny: dummyFace,
            pz: dummyFace,
            nz: dummyFace
        )

        let original: AtmosphereArchive = await .bake(.earth, detail: 1, workers: 4)

        let earthEntry: AuraArchive.Body = .init(
            name: "Earth",
            spheroid: .init(
                radius: 6371.0,
                relief: 1,
                tilt: 0.4084,
                flattening: 0.00335,
            ),
            albedo: dummyAlbedo,
            relief: dummyRelief,
            atmosphere: original.atmosphere
        )

        let moonEntry: AuraArchive.Body = .init(
            name: "The Moon",
            spheroid: .init(
                radius: 1737.4,
                relief: 1.5,
                tilt: 0.0269,
                flattening: 0.0,
            ),
            albedo: dummyAlbedo,
            relief: nil,
            atmosphere: nil
        )

        let archive: AuraArchive = .init(bodies: [earthEntry, moonEntry])
        let bytes: [UInt8] = try archive.serialize()
        #expect(!bytes.isEmpty)

        let deserialized: AuraArchive = try .deserialize(from: bytes)
        #expect(deserialized.bodies.count == 2)

        let roundtripEarth: AuraArchive.Body = try #require(deserialized["Earth"])
        #expect(roundtripEarth.spheroid.radius == 6371.0)
        #expect(roundtripEarth.spheroid.tilt == 0.4084)
        #expect(roundtripEarth.albedo.px == dummyFace)
        #expect(roundtripEarth.relief?.pz == dummyFace)
        #expect(roundtripEarth.atmosphere != nil)
        #expect(roundtripEarth.atmosphere?.parameters.radius_bottom == 6360000.0)

        let roundtripMoon: AuraArchive.Body = try #require(deserialized["The Moon"])
        #expect(roundtripMoon.spheroid.radius == 1737.4)
        #expect(roundtripMoon.spheroid.relief == 1.5)
        #expect(roundtripMoon.relief == nil)
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
            try ion.decode(atomic: AuraArchive.Spheroid.self)
        }
    }

    @Test static func TableDecompressionThrowsOnCorrupt() throws {
        let corrupt: [UInt8] = [0x01, 0x02, 0x03, 0x04]
        let descriptor: Atmosphere.Table = .init(
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
