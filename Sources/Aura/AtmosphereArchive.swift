import AuraDecoding
import Ion
import SystemIO
import SystemPackage

public struct AtmosphereArchive: Sendable, Equatable {
    @inlinable public static var currentVersion: UInt32 { 1 }

    public var manifest: Manifest

    public var version: UInt32 {
        get { self.manifest.version }
        set { self.manifest.version = newValue }
    }

    public var planets: [PlanetEntry] {
        get { self.manifest.planets }
        set { self.manifest.planets = newValue }
    }

    public init(manifest: Manifest) {
        self.manifest = manifest
    }

    public init(
        version: UInt32 = AtmosphereArchive.currentVersion,
        planets: [PlanetEntry]
    ) {
        self.manifest = .init(version: version, planets: planets)
    }

    public subscript(name: String) -> PlanetEntry? {
        self.manifest[name]
    }
}

extension AtmosphereArchive {
    /// Serializes the archive as a Gzip-compressed binary Ion structure.
    public func serialize() throws -> [UInt8] {
        let ion: Ion = .encode(atomic: self.manifest)
        return AtmosphereCompression.deflate(ion.bytes, level: 7)
    }

    /// Decompresses (if gzipped) and deserializes an AtmosphereArchive Ion structure.
    public static func deserialize(from archive: [UInt8]) throws -> AtmosphereArchive {
        let uncompressed: [UInt8]
        if  archive.starts(with: [0x1f, 0x8b]) {
            uncompressed = try AtmosphereCompression.inflate(archive[...])
        } else {
            uncompressed = archive
        }

        let manifest: Manifest = try Ion(bytes: uncompressed[...]).decode(atomic: Manifest.self)
        guard manifest.version == Self.currentVersion else {
            throw Error.unsupportedVersion(manifest.version)
        }
        return .init(manifest: manifest)
    }

    /// Extracts and decodes a specific lookup table for a planet.
    public func extractTable(
        for planet: String,
        table tableName: String
    ) throws -> [SIMD4<Float>] {
        guard let planetEntry: PlanetEntry = self.manifest[planet] else {
            throw Error.planetNotFound(planet)
        }
        guard let descriptor: TableDescriptor = planetEntry.tables[tableName] else {
            throw Error.tableNotFound(tableName)
        }

        return AtmosphereTableDecoder.decode(
            shuffled: descriptor.data,
            width: descriptor.width,
            height: descriptor.height,
            depth: descriptor.depth ?? 1
        )
    }

    /// Bakes one or more atmospheric configurations into a unified archive.
    public static func bake(
        configs: [AtmosphereConfig],
        workers: Int,
        detail: Int = 3,
    ) async throws -> AtmosphereArchive {
        guard 1 ... 5 ~= detail else {
            throw AtmosphereError.invalidDetail(detail)
        }

        var planets: [PlanetEntry] = []
        for config: AtmosphereConfig in configs {
            let atmosphere: Atmosphere = .from(
                config: config,
                resolutions: (
                    transmittance: .init(32, 8) &<< detail,
                    scattering: .init(4, 16, 4, 1) &<< detail,
                    irradiance: .init(8, 2) &<< detail
                )
            )

            let table: (
                transmittance: TransmittanceTable,
                mie: ScatteringTable,
                scattering: ScatteringTable,
                irradiance: IrradianceTable
            ) = await atmosphere.tables(workers: workers)

            // 1. Transmittance table
            let transmittanceWidth: Int = atmosphere.resolution.transmittance.x
            let transmittanceHeight: Int = atmosphere.resolution.transmittance.y
            let transmittanceBuffer: [SIMD4<Float>] = table.transmittance.buffer.map {
                .init(.init($0.x), .init($0.y), .init($0.z), 1.0)
            }
            let transmittanceShuffled: [UInt8] = AtmosphereCompression.filterAndShuffle(
                simd4: transmittanceBuffer,
                width: transmittanceWidth,
                height: transmittanceHeight,
                depth: 1
            )

            // 2. Scattering table (Mie merged into W)
            let scatteringWidth: Int = atmosphere.resolution.scattering.x
            let scatteringHeight: Int = atmosphere.resolution.scattering.y
            let scatteringDepth: Int = atmosphere.resolution.scattering.z
            let scatteringBuffer: [SIMD4<Float>] = zip(table.scattering.buffer, table.mie.buffer).map {
                .init(.init($0.x), .init($0.y), .init($0.z), .init($1.x))
            }
            let scatteringShuffled: [UInt8] = AtmosphereCompression.filterAndShuffle(
                simd4: scatteringBuffer,
                width: scatteringWidth,
                height: scatteringHeight,
                depth: scatteringDepth
            )

            // 3. Irradiance table
            let irradianceWidth: Int = atmosphere.resolution.irradiance.x
            let irradianceHeight: Int = atmosphere.resolution.irradiance.y
            let irradianceBuffer: [SIMD4<Float>] = table.irradiance.buffer.map {
                .init(.init($0.x), .init($0.y), .init($0.z), 1.0)
            }
            let irradianceShuffled: [UInt8] = AtmosphereCompression.filterAndShuffle(
                simd4: irradianceBuffer,
                width: irradianceWidth,
                height: irradianceHeight,
                depth: 1
            )

            // 4. Physical parameters & resolutions
            let p: [Float] = atmosphere.serialized.map(Float.init)
            let parameters: AtmosphereParameters = .init(
                radius_bottom: p[0],
                radius_top: p[1],
                radius_sun: p[2],
                mu_s_min: p[3],
                rayleigh_scattering: [p[4], p[5], p[6]],
                mie_scattering: [p[7], p[8], p[9]],
                mie_g: p[10],
                resolution_transmittance: [.init(p[11]), .init(p[12])],
                resolution_scattering4_R: .init(p[13]),
                resolution_scattering4_M: .init(p[14]),
                resolution_scattering4_MS: .init(p[15]),
                resolution_scattering4_N: .init(p[16]),
                resolution_irradiance: [.init(p[17]), .init(p[18])],
                irradiance: [p[19], p[20], p[21]]
            )

            let transmittanceDescriptor: TableDescriptor = .init(
                width: transmittanceWidth,
                height: transmittanceHeight,
                depth: nil,
                data: transmittanceShuffled
            )

            let scatteringDescriptor: TableDescriptor = .init(
                width: scatteringWidth,
                height: scatteringHeight,
                depth: scatteringDepth,
                data: scatteringShuffled
            )

            let irradianceDescriptor: TableDescriptor = .init(
                width: irradianceWidth,
                height: irradianceHeight,
                depth: nil,
                data: irradianceShuffled
            )

            let entry: PlanetEntry = .init(
                name: config.name,
                parameters: params,
                tables: .init(
                    transmittance: transmittanceDescriptor,
                    scattering: scatteringDescriptor,
                    irradiance: irradianceDescriptor
                )
            )
            planets.append(entry)
        }

        return .init(
            manifest: .init(version: Self.currentVersion, planets: planets)
        )
    }

    /// Serializes and writes the compressed archive to the specified file path.
    public func write(to path: FilePath) throws {
        let compressedBytes: [UInt8] = try self.serialize()
        _ = try path.open(
            .writeOnly,
            permissions: (.rw, .rw, .r),
            options: [.create, .truncate]
        ) { descriptor in
            try compressedBytes.withUnsafeBytes { raw in
                try descriptor.writeAll(raw)
            }
        }
    }
}
