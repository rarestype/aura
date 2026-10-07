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
        let count: (x: Int, y: Int, z: Int) = (32, 16, 4)
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(count.x * count.y * count.z)

        for z: Int in 0 ..< count.z {
            for y: Int in 0 ..< count.y {
                for x: Int in 0 ..< count.x {
                    let fx: Float = Float.init(x) / Float.init(count.x)
                    let fy: Float = Float.init(y) / Float.init(count.y)
                    let fz: Float = Float.init(z) / Float.init(count.z)
                    data.append(.init(fx * 1.5, fy * 2.0, fz * 0.8, (fx + fy) * 0.2))
                }
            }
        }

        let compressed: [UInt8] = TableEncoder.compress(
            simd4: data,
            count: count
        )

        #expect(compressed.count < data.count * MemoryLayout<SIMD4<Float>>.size)
        #expect(
            try Atmosphere.Table.init(
                x: count.x,
                y: count.y,
                z: count.z,
                bytes: compressed
            ).decompress() == data
        )
    }

    @Test static func TableCompression2DRoundtrip() throws {
        let count: (x: Int, y: Int, z: Int) = (64, 16, 1)
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(count.x * count.y)

        for y: Int in 0 ..< count.y {
            for x: Int in 0 ..< count.x {
                let fx: Float = Float.init(x) / Float.init(count.x)
                let fy: Float = Float.init(y) / Float.init(count.y)
                data.append(.init(fx * 1.5, fy * 2.0, (fx + fy) * 0.5, 1.0))
            }
        }

        let compressed: [UInt8] = TableEncoder.compress(
            simd4: data,
            count: count
        )

        #expect(
            try Atmosphere.Table.init(
                x: count.x,
                y: count.y,
                z: count.z,
                bytes: compressed
            ).decompress() == data
        )
    }

    @Test static func TableDecoderDirect() throws {
        let count: (x: Int, y: Int, z: Int) = (16, 8, 2)
        var data: [SIMD4<Float>] = []
        data.reserveCapacity(count.x * count.y * count.z)
        for z: Int in 0 ..< count.z {
            for y: Int in 0 ..< count.y {
                for x: Int in 0 ..< count.x {
                    data.append(
                        .init(
                            Float.init(x),
                            Float.init(y),
                            Float.init(z),
                            Float.init(x + y + z)
                        )
                    )
                }
            }
        }

        let encoded: [UInt8] = TableEncoder.encode(
            simd4: data,
            count: count
        )

        #expect(TableDecoder.decode(bytes: encoded, count: count) == data)
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
        for table: Atmosphere.Table in tables {
            totalRawBytes += table.x * table.y * table.z * MemoryLayout<SIMD4<Float>>.stride
        }

        let ion: Ion = .encode(atomic: archive)
        #expect(ion.bytes.count > 0)
        #expect(ion.bytes.count < totalRawBytes)

        let deserialized: AtmosphereArchive = try ion.decode()
        #expect(deserialized.name == "Earth")
        #expect(deserialized.atmosphere.parameters.radius_bottom == 6360000.0)

        let transmittance: Atmosphere.Table = deserialized.atmosphere.transmittance
        #expect(try transmittance.decompress().count == transmittance.x * transmittance.y)

        let scattering: Atmosphere.Table = deserialized.atmosphere.scattering
        #expect(try scattering.decompress().count == scattering.x * scattering.y * scattering.z)

        let irradiance: Atmosphere.Table = deserialized.atmosphere.irradiance
        #expect(try irradiance.decompress().count == irradiance.x * irradiance.y)
    }

    @Test static func AtmosphereArchiveMultiPlanetBake() async throws {
        let archives: [AtmosphereArchive] = await AtmosphereArchive.bake(
            bodies: [.earth, .mars],
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
        let dummyFace: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00]
        let dummyAlbedo: AuraArchive.Cubemap = .init(
            px: dummyFace, nx: dummyFace, py: dummyFace,
            ny: dummyFace, pz: dummyFace, nz: dummyFace
        )
        let dummyRelief: AuraArchive.Cubemap = .init(
            px: dummyFace, nx: dummyFace, py: dummyFace,
            ny: dummyFace, pz: dummyFace, nz: dummyFace
        )

        let archive: AtmosphereArchive = await .bake(.earth, detail: 1, workers: 4)
        let aura: AuraArchive = .init(
            bodies: [
                .init(
                    name: "Earth",
                    spheroid: .init(
                        radius: 6371.0,
                        relief: 1,
                        tilt: 0.4084,
                        flattening: 0.00335
                    ),
                    albedo: dummyAlbedo,
                    relief: dummyRelief,
                    atmosphere: archive.atmosphere
                ),
                .init(
                    name: "The Moon",
                    spheroid: .init(radius: 1737.4, relief: 1.5, tilt: 0.0269, flattening: 0.0),
                    albedo: dummyAlbedo,
                    relief: nil,
                    atmosphere: nil
                )
            ]
        )

        let deserialized: AuraArchive = try .deserialize(from: aura.serialize())
        #expect(deserialized.bodies.count == 2)

        let earth: AuraArchive.Body = try #require(deserialized["Earth"])
        #expect(earth.spheroid.radius == 6371.0)
        #expect(earth.spheroid.tilt == 0.4084)
        #expect(earth.albedo.px == dummyFace)
        #expect(earth.relief?.pz == dummyFace)
        #expect(earth.atmosphere != nil)
        #expect(earth.atmosphere?.parameters.radius_bottom == 6360000.0)

        let moon: AuraArchive.Body = try #require(deserialized["The Moon"])
        #expect(moon.spheroid.radius == 1737.4)
        #expect(moon.spheroid.relief == 1.5)
        #expect(moon.relief == nil)
        #expect(moon.atmosphere == nil)
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
        #expect(throws: (any Error).self) {
            _ = try Atmosphere.Table.init(
                x: 16,
                y: 16,
                z: 1,
                bytes: [0x01, 0x02, 0x03, 0x04]
            ).decompress()
        }
    }
}
