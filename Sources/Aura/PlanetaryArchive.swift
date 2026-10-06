public import Ion

public struct PlanetaryArchive: Sendable {
    public static var currentVersion: UInt32 { 2 }

    public var version: UInt32
    public var planets: [PlanetEntry]

    public init(
        version: UInt32 = Self.currentVersion,
        planets: [PlanetEntry]
    ) {
        self.version = version
        self.planets = planets
    }

    public subscript(name: String) -> PlanetEntry? {
        self.planets.first { $0.name == name }
    }
}

extension PlanetaryArchive {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case version
        case planets
    }
}

extension PlanetaryArchive: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.version] = self.version
        ion[.planets] = self.planets
    }
}

extension PlanetaryArchive: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            version: try ion[.version].decode(),
            planets: try ion[.planets].decode()
        )
    }
}

extension PlanetaryArchive {
    /// Serializes the archive as an uncompressed binary Ion archive.
    public func serialize() throws -> [UInt8] {
        let ion: Ion = .encode(atomic: self)
        return .init(ion.bytes)
    }

    /// Deserializes a PlanetaryArchive from binary Ion bytes.
    public static func deserialize(from archive: [UInt8]) throws -> PlanetaryArchive {
        let ion: Ion = .init(bytes: archive[...])
        let decoded: PlanetaryArchive = try ion.decode(atomic: PlanetaryArchive.self)
        if  decoded.version != Self.currentVersion {
            throw PlanetaryArchiveError.unsupportedVersion(decoded.version)
        }
        return decoded
    }
}
