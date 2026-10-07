import ArgumentParser
import Aura
import AuraTesting
import CRC
import Ion
import SystemIO
import SystemPackage

@main struct AuraGoldenTests {
    static var goldenCRC32: (transmittance: UInt32, irradiance: UInt32, scattering: UInt32) {
        (0xAB53BAD0, 0xB193C82B, 0xA71A2E72)
    }

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
        print("1. Baking Earth atmosphere archive at detail 3...")
        let clock: ContinuousClock = .init()
        let start: ContinuousClock.Instant = clock.now
        let archive: AtmosphereArchive = await .bake(.earth, detail: 3, workers: self.threads)
        print("   Detail 3 precomputation finished in \(start.duration(to: clock.now))!")

        print("2. Verifying physical parameters...")
        let params: AtmosphereParameters = archive.atmosphere.parameters
        guard params.radius_bottom == 6360000.0,
        params.radius_top == 6420000.0,
        abs(params.mu_s_min - -0.20791169) < 1e-6,
        params.mie_g == 0.8 else {
            fatalError("Verification failed: Parameter mismatch!")
        }
        print("   Parameters verified successfully!")

        print("3. Extracting tables and checking CRC32 against golden reference...")

        let transmittance: Atmosphere.Table = archive.atmosphere.transmittance
        guard transmittance.x == 256, transmittance.y == 64 else {
            fatalError("Verification failed: Unexpected transmittance resolution!")
        }
        let transmittanceData: [SIMD4<Float>] = try transmittance.decompress()
        let transmittanceCRC: UInt32 = transmittanceData.withUnsafeBytes {
            CRC32.init(hashing: $0).checksum
        }
        print(
            """
               Transmittance CRC32: 0x\(
                String(transmittanceCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(Self.goldenCRC32.transmittance, radix: 16, uppercase: true)
            )]
            """
        )
        guard transmittanceCRC == Self.goldenCRC32.transmittance else {
            fatalError("Verification failed: Transmittance CRC32 mismatch!")
        }

        let irradiance: Atmosphere.Table = archive.atmosphere.irradiance
        guard irradiance.x == 64, irradiance.y == 16 else {
            fatalError("Verification failed: Unexpected irradiance resolution!")
        }
        let irradianceData: [SIMD4<Float>] = try irradiance.decompress()
        let irradianceCRC: UInt32 = irradianceData.withUnsafeBytes {
            CRC32.init(hashing: $0).checksum
        }
        print(
            """
               Irradiance    CRC32: 0x\(
                String(irradianceCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(Self.goldenCRC32.irradiance, radix: 16, uppercase: true)
            )]
            """
        )
        guard irradianceCRC == Self.goldenCRC32.irradiance else {
            fatalError("Verification failed: Irradiance CRC32 mismatch!")
        }

        let scattering: Atmosphere.Table = archive.atmosphere.scattering
        guard scattering.x == 256, scattering.y == 128, scattering.z == 32 else {
            fatalError("Verification failed: Unexpected scattering resolution!")
        }
        let scatteringData: [SIMD4<Float>] = try scattering.decompress()
        let scatteringCRC: UInt32 = scatteringData.withUnsafeBytes {
            CRC32.init(hashing: $0).checksum
        }
        print(
            """
               Scattering    CRC32: 0x\(
                String(scatteringCRC, radix: 16, uppercase: true)
            ) [expected: 0x\(
                String(Self.goldenCRC32.scattering, radix: 16, uppercase: true)
            )]
            """
        )
        guard scatteringCRC == Self.goldenCRC32.scattering else {
            fatalError("Verification failed: Scattering CRC32 mismatch!")
        }

        if let goldenDir: String = Environment["GOLDEN_TABLES_DIR"] {
            let goldenPath: FilePath = .init(goldenDir)
            if (try? goldenPath.exists) == true {
                print("   Comparing float-by-float against golden files in '\(goldenPath)'...")
                try Self.verifyAgainstExternalGolden(
                    dir: goldenPath,
                    transmittance: transmittanceData,
                    irradiance: irradianceData,
                    scattering: scatteringData
                )
                print("   Bit-for-bit exact match across all 4,263,936 floating-point values!")
            } else {
                print(
                    """
                       GOLDEN_TABLES_DIR specified but '\(
                        goldenPath
                    )' does not exist (skipping).
                    """
                )
            }
        }

        print("4. Verifying archive serialization and deserialization roundtrip...")
        let ion: Ion = .encode(atomic: archive)
        let deserialized: AtmosphereArchive = try ion.decode()
        guard try deserialized.atmosphere.scattering.decompress() == scatteringData else {
            fatalError("Verification failed: Table roundtrip mismatch!")
        }
        print("   Archive serialized (\(ion.bytes.count) bytes) and deserialized successfully!")

        print("💖 output matches golden reference!")
    }

    private static func verifyAgainstExternalGolden(
        dir: FilePath,
        transmittance: [SIMD4<Float>],
        irradiance: [SIMD4<Float>],
        scattering: [SIMD4<Float>]
    ) throws {
        let files: [(name: String, path: FilePath, data: [SIMD4<Float>], offset: Int)] = [
            (
                "Transmittance",
                dir.appending("earth-transmittance-3x.float32"),
                transmittance,
                16
            ),
            ("Irradiance", dir.appending("earth-irradiance-3x.float32"), irradiance, 16),
            (
                "Scattering",
                dir.appending("earth-scattering-combined-3x.float32"),
                scattering,
                20
            )
        ]

        for file: (name: String, path: FilePath, data: [SIMD4<Float>], offset: Int) in files {
            if  let bytes: [UInt8] = try? file.path.read([UInt8].self),
                    bytes.count >= file.offset + file.data.count * 16 {
                let golden: [Float] = bytes[
                    file.offset ..< file.offset + file.data.count * 16
                ].withUnsafeBytes {
                    $0.bindMemory(to: UInt32.self).map {
                        .init(bitPattern: UInt32.init(bigEndian: $0))
                    }
                }
                file.data.withUnsafeBytes {
                    let baked: UnsafeBufferPointer<Float> = $0.bindMemory(to: Float.self)
                    for i: Int in 0 ..< golden.count {
                        if  golden[i] != baked[i] {
                            fatalError(
                                """
                                \(file.name) float mismatch at index \(i): golden=\(
                                    golden[i]
                                ) vs baked=\(
                                    baked[i]
                                )
                                """
                            )
                        }
                    }
                }
            }
        }
    }
}
