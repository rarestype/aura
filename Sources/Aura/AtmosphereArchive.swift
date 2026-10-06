import AuraDecoding
public import Ion
import SystemIO
public import SystemPackage

public struct AtmosphereArchive {
    public static var currentVersion: UInt32 { 1 }

    public var version: UInt32
    public var name: String
    public var atmosphere: AtmosphereDescriptor

    public init(
        version: UInt32 = Self.currentVersion,
        name: String,
        atmosphere: AtmosphereDescriptor
    ) {
        self.version = version
        self.name = name
        self.atmosphere = atmosphere
    }
}

extension AtmosphereArchive {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case version
        case name
        case atmosphere
    }
}

extension AtmosphereArchive: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.version] = self.version
        ion[.name] = self.name
        ion[.atmosphere] = self.atmosphere
    }
}

extension AtmosphereArchive: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            version: try ion[.version].decode(),
            name: try ion[.name].decode(),
            atmosphere: try ion[.atmosphere].decode()
        )
    }
}

extension AtmosphereArchive {
    /// Serializes the archive as an uncompressed binary Ion structure.
    public func serialize() throws -> [UInt8] {
        let ion: Ion = .encode(atomic: self)
        return .init(ion.bytes)
    }

    /// Deserializes an AtmosphereArchive from binary Ion bytes.
    public static func deserialize(from archive: [UInt8]) throws -> AtmosphereArchive {
        let ion: Ion = .init(bytes: archive[...])
        let decoded: AtmosphereArchive = try ion.decode(atomic: AtmosphereArchive.self)
        guard decoded.version == Self.currentVersion else {
            throw AtmosphereArchiveError.unsupportedVersion(decoded.version)
        }
        return decoded
    }

    /// Bakes an atmospheric configuration into an uncompressed .atmo archive.
    public static func bake(
        config: AtmosphereConfig,
        workers: Int,
        detail: Int = 3
    ) async throws -> AtmosphereArchive {
        guard 1 ... 5 ~= detail else {
            throw AtmosphereError.invalidDetail(detail)
        }

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
        let transmittance: AtmosphereDescriptor.TableDescriptor = .init(
            width: atmosphere.resolution.transmittance.x,
            height: atmosphere.resolution.transmittance.y,
            depth: nil,
            data: TableCompression.deflate(
                TableCompression.filterAndShuffle(
                    simd4: table.transmittance.buffer.map {
                        .init(.init($0.x), .init($0.y), .init($0.z), 1.0)
                    },
                    width: atmosphere.resolution.transmittance.x,
                    height: atmosphere.resolution.transmittance.y,
                    depth: 1
                )
            )
        )

        // 2. Scattering table (Mie merged into W)
        let scattering: AtmosphereDescriptor.TableDescriptor = .init(
            width: atmosphere.resolution.scattering.x,
            height: atmosphere.resolution.scattering.y,
            depth: atmosphere.resolution.scattering.z,
            data: TableCompression.deflate(
                TableCompression.filterAndShuffle(
                    simd4: zip(table.scattering.buffer, table.mie.buffer).map {
                        .init(.init($0.x), .init($0.y), .init($0.z), .init($1.x))
                    },
                    width: atmosphere.resolution.scattering.x,
                    height: atmosphere.resolution.scattering.y,
                    depth: atmosphere.resolution.scattering.z
                )
            )
        )

        // 3. Irradiance table
        let irradiance: AtmosphereDescriptor.TableDescriptor = .init(
            width: atmosphere.resolution.irradiance.x,
            height: atmosphere.resolution.irradiance.y,
            depth: nil,
            data: TableCompression.deflate(
                TableCompression.filterAndShuffle(
                    simd4: table.irradiance.buffer.map {
                        .init(.init($0.x), .init($0.y), .init($0.z), 1.0)
                    },
                    width: atmosphere.resolution.irradiance.x,
                    height: atmosphere.resolution.irradiance.y,
                    depth: 1
                )
            )
        )

        // 4. Physical parameters & resolutions
        let parameters: AtmosphereParameters = .init(
            radius_bottom: atmosphere.radius.bottom,
            radius_top: atmosphere.radius.top,
            radius_sun: atmosphere.radius.sun,
            mu_s_min: atmosphere.μsmin,
            rayleigh_scattering: atmosphere.rayleigh.scattering,
            mie_scattering: atmosphere.mie.scattering,
            mie_g: atmosphere.mie.g,
            resolution_transmittance: atmosphere.resolution.transmittance,
            resolution_scattering4_R: atmosphere.resolution.scattering4.R,
            resolution_scattering4_M: atmosphere.resolution.scattering4.M,
            resolution_scattering4_MS: atmosphere.resolution.scattering4.MS,
            resolution_scattering4_N: atmosphere.resolution.scattering4.N,
            resolution_irradiance: atmosphere.resolution.irradiance,
            irradiance: atmosphere.irradiance
        )

        let descriptor: AtmosphereDescriptor = .init(
            parameters: parameters,
            tables: .init(
                transmittance: transmittance,
                scattering: scattering,
                irradiance: irradiance
            )
        )

        return .init(
            version: Self.currentVersion,
            name: config.name,
            atmosphere: descriptor
        )
    }

    /// Bakes multiple atmospheric configurations.
    public static func bake(
        configs: [AtmosphereConfig],
        workers: Int,
        detail: Int = 3
    ) async throws -> [AtmosphereArchive] {
        var archives: [AtmosphereArchive] = []
        archives.reserveCapacity(configs.count)
        for config: AtmosphereConfig in configs {
            let archive: AtmosphereArchive = try await Self.bake(
                config: config,
                workers: workers,
                detail: detail
            )
            archives.append(archive)
        }
        return archives
    }

    /// Serializes and writes the archive to the specified file path.
    public func write(to path: FilePath) throws {
        let bytes: [UInt8] = try self.serialize()
        try path.overwrite(with: bytes[...])
    }
}
