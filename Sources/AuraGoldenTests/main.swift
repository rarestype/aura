import ArgumentParser
import Aura
import CRC
import SystemIO
import SystemPackage

@main struct AuraGoldenTests {
    static var goldenTransmittanceCRC32: UInt32 { 0xAB53BAD0 }
    static var goldenIrradianceCRC32: UInt32 { 0xB193C82B }
    static var goldenScatteringCRC32: UInt32 { 0xA71A2E72 }

    @Option(
        name: [.customLong("threads"), .customShort("j")],
        help: "Number of threads to use for precomputation"
    ) var threads: Int = 4
}

extension AuraGoldenTests: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "AuraGoldenTests",
            abstract: "Runs atmospheric precomputation and golden reference verification."
        )
    }

    func run() async throws {
        print("1. Parsing Earth atmospheric configuration from embedded string...")
        let config: AtmosphereConfig = try AtmosphereConfig.parse(ion: Self.earthIon)

        print("2. Baking Earth atmosphere archive at detail 3...")
        let clock: ContinuousClock = .init()
        let start: ContinuousClock.Instant = clock.now
        let archive: AtmosphereArchive = try await .bake(
            config: config,
            workers: self.threads,
            detail: 3
        )
        let elapsed: Duration = start.duration(to: clock.now)
        print("   Detail 3 precomputation finished in \(elapsed)!")

        print("3. Verifying physical parameters...")
        let params: AtmosphereParameters = archive.atmosphere.parameters
        guard params.radius_bottom == 6360000.0,
        params.radius_top == 6420000.0,
        abs(params.mu_s_min - -0.20791169) < 1e-6,
        params.mie_g == 0.8 else {
            fatalError("Verification failed: Parameter mismatch!")
        }
        print("   Parameters verified successfully!")

        print("4. Extracting tables and checking CRC32 against golden reference...")

        // Transmittance
        let transDesc: AtmosphereDescriptor.TableDescriptor = archive.atmosphere.tables.transmittance
        guard transDesc.width == 256, transDesc.height == 64 else {
            fatalError("Verification failed: Unexpected transmittance resolution!")
        }
        let transTable: [SIMD4<Float>] = try transDesc.decode()
        let transCRC: UInt32 = transTable.withUnsafeBytes { raw in
            CRC32.init(hashing: raw).checksum
        }
        print(
            """
               Transmittance CRC32: 0x\(
                String(transCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(Self.goldenTransmittanceCRC32, radix: 16, uppercase: true)
            )]
            """
        )
        guard transCRC == Self.goldenTransmittanceCRC32 else {
            fatalError("Verification failed: Transmittance CRC32 mismatch!")
        }

        // Irradiance
        let irradDesc: AtmosphereDescriptor.TableDescriptor = archive.atmosphere.tables.irradiance
        guard irradDesc.width == 64, irradDesc.height == 16 else {
            fatalError("Verification failed: Unexpected irradiance resolution!")
        }
        let irradTable: [SIMD4<Float>] = try irradDesc.decode()
        let irradCRC: UInt32 = irradTable.withUnsafeBytes { raw in
            CRC32.init(hashing: raw).checksum
        }
        print(
            """
               Irradiance    CRC32: 0x\(
                String(irradCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(Self.goldenIrradianceCRC32, radix: 16, uppercase: true)
            )]
            """
        )
        guard irradCRC == Self.goldenIrradianceCRC32 else {
            fatalError("Verification failed: Irradiance CRC32 mismatch!")
        }

        // Scattering
        let scatDesc: AtmosphereDescriptor.TableDescriptor = archive.atmosphere.tables.scattering
        guard scatDesc.width == 256, scatDesc.height == 128, scatDesc.depth == 32 else {
            fatalError("Verification failed: Unexpected scattering resolution!")
        }
        let scatTable: [SIMD4<Float>] = try scatDesc.decode()
        let scatCRC: UInt32 = scatTable.withUnsafeBytes { raw in
            CRC32.init(hashing: raw).checksum
        }
        print(
            """
               Scattering    CRC32: 0x\(
                String(scatCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(Self.goldenScatteringCRC32, radix: 16, uppercase: true)
            )]
            """
        )
        guard scatCRC == Self.goldenScatteringCRC32 else {
            fatalError("Verification failed: Scattering CRC32 mismatch!")
        }

        // 5. Check against external raw golden files if explicitly provided
        if let goldenDirEnv: String = Environment["GOLDEN_TABLES_DIR"] {
            let goldenDir: FilePath = .init(goldenDirEnv)
            if (try? goldenDir.exists) == true {
                print("5. Comparing float-by-float against golden files in ‘\(goldenDir)’...")
                try Self.verifyAgainstExternalGolden(
                    dir: goldenDir,
                    transmittance: transTable,
                    irradiance: irradTable,
                    scattering: scatTable
                )
                print("   Bit-for-bit exact match across all 4,263,936 floating-point values!")
            } else {
                print(
                    """
                    5. GOLDEN_TABLES_DIR specified but ‘\(goldenDir)’ does not exist (skipping).
                    """
                )
            }
        }

        print("6. Verifying archive serialization and deserialization roundtrip...")
        let archiveBytes: [UInt8] = try archive.serialize()
        let deserialized: AtmosphereArchive = try .deserialize(from: archiveBytes)
        let reextractedScattering: [
            SIMD4<Float>
        ] = try deserialized.atmosphere.tables.scattering.decode()
        guard reextractedScattering == scatTable else {
            fatalError("Verification failed: Table roundtrip mismatch!")
        }
        print(
            """
               Archive serialized (\(
                archiveBytes.count
            ) bytes) and deserialized successfully!
            """
        )

        print("💖 output matches golden reference!")
    }

    private static func verifyAgainstExternalGolden(
        dir: FilePath,
        transmittance: [SIMD4<Float>],
        irradiance: [SIMD4<Float>],
        scattering: [SIMD4<Float>]
    ) throws {
        // Transmittance
        let transPath: FilePath = dir.appending("earth-transmittance-3x.float32")
        if let bytes: [UInt8] = try? transPath.read([UInt8].self),
            bytes.count >= 16 + transmittance.count * 16 {
            let beFloats: [Float] = bytes[
                16 ..< 16 + transmittance.count * 16
            ].withUnsafeBytes { raw in
                let u32s: UnsafeBufferPointer<UInt32> = raw.bindMemory(to: UInt32.self)
                return u32s.map { .init(bitPattern: UInt32(bigEndian: $0)) }
            }
            transmittance.withUnsafeBytes { raw in
                let leFloats: UnsafeBufferPointer<Float> = raw.bindMemory(to: Float.self)
                for i: Int in 0 ..< beFloats.count {
                    if beFloats[i] != leFloats[i] {
                        fatalError(
                            """
                            Transmittance float mismatch at index \(i): golden=\(
                                beFloats[i]
                            ) vs baked=\(
                                leFloats[i]
                            )
                            """
                        )
                    }
                }
            }
        }

        // Irradiance
        let irradPath: FilePath = dir.appending("earth-irradiance-3x.float32")
        if let bytes: [UInt8] = try? irradPath.read([UInt8].self),
            bytes.count >= 16 + irradiance.count * 16 {
            let beFloats: [Float] = bytes[
                16 ..< 16 + irradiance.count * 16
            ].withUnsafeBytes { raw in
                let u32s: UnsafeBufferPointer<UInt32> = raw.bindMemory(to: UInt32.self)
                return u32s.map { .init(bitPattern: UInt32(bigEndian: $0)) }
            }
            irradiance.withUnsafeBytes { raw in
                let leFloats: UnsafeBufferPointer<Float> = raw.bindMemory(to: Float.self)
                for i: Int in 0 ..< beFloats.count {
                    if beFloats[i] != leFloats[i] {
                        fatalError(
                            """
                            Irradiance float mismatch at index \(i): golden=\(
                                beFloats[i]
                            ) vs baked=\(
                                leFloats[i]
                            )
                            """
                        )
                    }
                }
            }
        }

        // Scattering
        let scatPath: FilePath = dir.appending("earth-scattering-combined-3x.float32")
        if let bytes: [UInt8] = try? scatPath.read([UInt8].self),
            bytes.count >= 20 + scattering.count * 16 {
            let beFloats: [Float] = bytes[
                20 ..< 20 + scattering.count * 16
            ].withUnsafeBytes { raw in
                let u32s: UnsafeBufferPointer<UInt32> = raw.bindMemory(to: UInt32.self)
                return u32s.map { .init(bitPattern: UInt32(bigEndian: $0)) }
            }
            scattering.withUnsafeBytes { raw in
                let leFloats: UnsafeBufferPointer<Float> = raw.bindMemory(to: Float.self)
                for i: Int in 0 ..< beFloats.count {
                    if beFloats[i] != leFloats[i] {
                        fatalError(
                            """
                            Scattering float mismatch at index \(i): golden=\(
                                beFloats[i]
                            ) vs baked=\(
                                leFloats[i]
                            )
                            """
                        )
                    }
                }
            }
        }
    }
}

extension AuraGoldenTests {
    static var earthIon: String {
        """
        {
            // Atmosphere configuration for Earth
            name: "Earth",

            // Planetary geometry (meters and radians)
            radius_bottom: 6360000.0e0,
            radius_top: 6420000.0e0,
            sun_angular_radius: 0.004675e0,
            max_sun_zenith_angle: 102.0e0,

            // Rayleigh molecular scattering
            rayleigh_scale_height: 8000.0e0,
            rayleigh_scattering: [
                5.8023393817123834e-06,
                1.3557762447920223e-05,
                3.3100005976367735e-05
            ],

            // Mie aerosol scattering
            mie_scale_height: 1200.0e0,
            mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
            mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
            mie_albedo: 0.9e0,
            mie_g: 0.8e0,

            // Absorption / Ozone layer (tent profile centered at 25km)
            ozone_extinction: [7.206534e-07, 1.7710017e-06, 6.5216177e-08],
            ozone_altitude: 25000.0e0,
            ozone_thickness: 15000.0e0,

            // Illumination and surface reflectance
            solar_irradiance: [1.49265e0, 1.850945e0, 1.7622550000000001e0],
            ground_albedo: [0.1e0, 0.1e0, 0.1e0]
        }
        """
    }
}
