import AuraEncoding
public import Ion

public struct AtmosphereArchive {
    public var name: String
    public var atmosphere: Atmosphere

    public init(
        name: String,
        atmosphere: Atmosphere
    ) {
        self.name = name
        self.atmosphere = atmosphere
    }
}
extension AtmosphereArchive {
    public static var version: UInt32 { 1 }
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
        ion[.version] = Self.version
        ion[.name] = self.name
        ion[.atmosphere] = self.atmosphere
    }
}

extension AtmosphereArchive: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        let version: Int = try ion[.version].decode()
        if  version != Self.version {
            throw VersionError.unsupported(version)
        }
        self.init(
            name: try ion[.name].decode(),
            atmosphere: try ion[.atmosphere].decode()
        )
    }
}

extension AtmosphereArchive {
    /// Serializes the archive as an uncompressed binary Ion structure.
    @available(*, deprecated, message: "Use Ion.encode(atomic:) instead")
    public func serialize() throws -> Ion {
        .encode(atomic: self)
    }

    /// Deserializes an AtmosphereArchive from binary Ion bytes.
    @available(*, deprecated, message: "Use Ion.decode(atomic:) instead")
    public static func deserialize(from archive: ArraySlice<UInt8>) throws -> Self {
        let ion: Ion = .init(bytes: archive)
        return try ion.decode(atomic: AtmosphereArchive.self)
    }
}

extension AtmosphereArchive {
    /// Bakes an atmospheric configuration into an uncompressed .atmo archive.
    public static func bake(
        _ body: AtmosphereConfiguration,
        detail: Int,
        workers: Int,
    ) async -> AtmosphereArchive {
        let atmosphere: AtmosphereContext = .load(
            from: body,
            resolutions: (
                transmittance: .init(32, 8) &<< detail,
                scattering: .init(4, 16, 4, 1) &<< detail,
                irradiance: .init(8, 2) &<< detail
            )
        )

        let table: (
            transmittance: AtmosphereContext.Transmittance,
            mie: AtmosphereContext.Scattering,
            scattering: AtmosphereContext.Scattering,
            irradiance: AtmosphereContext.Irradiance
        ) = await atmosphere.tables(workers: workers)

        // 1. Transmittance table
        let transmittance: Atmosphere.Table = .init(
            x: atmosphere.resolution.transmittance.x,
            y: atmosphere.resolution.transmittance.y,
            z: 1,
            bytes: TableEncoder.compress(
                simd4: table.transmittance.buffer.map {
                    .init(.init($0.x), .init($0.y), .init($0.z), 1.0)
                },
                count: (
                    atmosphere.resolution.transmittance.x,
                    atmosphere.resolution.transmittance.y,
                    1
                )
            )
        )

        // 2. Scattering table (Mie merged into W)
        let scattering: Atmosphere.Table = .init(
            x: atmosphere.resolution.scattering.x,
            y: atmosphere.resolution.scattering.y,
            z: atmosphere.resolution.scattering.z,
            bytes: TableEncoder.compress(
                simd4: zip(table.scattering.buffer, table.mie.buffer).map {
                    .init(.init($0.x), .init($0.y), .init($0.z), .init($1.x))
                },
                count: (
                    atmosphere.resolution.scattering.x,
                    atmosphere.resolution.scattering.y,
                    atmosphere.resolution.scattering.z
                )
            )
        )

        // 3. Irradiance table
        let irradiance: Atmosphere.Table = .init(
            x: atmosphere.resolution.irradiance.x,
            y: atmosphere.resolution.irradiance.y,
            z: 1,
            bytes: TableEncoder.compress(
                simd4: table.irradiance.buffer.map {
                    .init(.init($0.x), .init($0.y), .init($0.z), 1.0)
                },
                count: (
                    atmosphere.resolution.irradiance.x,
                    atmosphere.resolution.irradiance.y,
                    1
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

        return .init(
            name: body.name,
            atmosphere: .init(
                transmittance: transmittance,
                scattering: scattering,
                irradiance: irradiance,
                parameters: parameters
            )
        )
    }

    /// Bakes multiple atmospheric configurations.
    public static func bake(
        bodies: [AtmosphereConfiguration],
        detail: Int,
        workers: Int,
    ) async -> [AtmosphereArchive] {
        var archives: [AtmosphereArchive] = []
        ;   archives.reserveCapacity(bodies.count)
        for body: AtmosphereConfiguration in bodies {
            archives.append(await .bake(body, detail: detail, workers: workers))
        }
        return archives
    }
}
