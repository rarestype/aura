public import Ion

extension AtmosphereArchive {
    public struct Manifest: Sendable, Equatable {
        public var version: UInt32
        public var planets: [PlanetEntry]

        public init(
            version: UInt32 = AtmosphereArchive.currentVersion,
            planets: [PlanetEntry]
        ) {
            self.version = version
            self.planets = planets
        }

        public subscript(name: String) -> PlanetEntry? {
            self.planets[name]
        }
    }
}

extension AtmosphereArchive.Manifest {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case version
        case planets
    }
}

extension AtmosphereArchive.Manifest: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.version] = self.version
        ion[.planets] = self.planets
    }
}

extension AtmosphereArchive.Manifest: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            version: try ion[.version].decode(),
            planets: try ion[.planets].decode()
        )
    }
}

extension Collection where Element == AtmosphereArchive.PlanetEntry {
    public subscript(name: String) -> AtmosphereArchive.PlanetEntry? {
        self.first { $0.name == name }
    }
}
