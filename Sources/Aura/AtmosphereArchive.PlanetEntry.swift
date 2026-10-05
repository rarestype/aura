public import Ion

extension AtmosphereArchive {
    public struct PlanetEntry: Sendable, Equatable {
        public var name: String
        public var parameters: AtmosphereParameters
        public var tables: Tables

        public init(
            name: String,
            parameters: AtmosphereParameters,
            tables: Tables
        ) {
            self.name = name
            self.parameters = parameters
            self.tables = tables
        }
    }
}

extension AtmosphereArchive.PlanetEntry {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case name
        case parameters
        case tables
    }
}

extension AtmosphereArchive.PlanetEntry: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.name] = self.name
        ion[.parameters] = self.parameters
        ion[.tables] = self.tables
    }
}

extension AtmosphereArchive.PlanetEntry: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            name: try ion[.name].decode(),
            parameters: try ion[.parameters].decode(),
            tables: try ion[.tables].decode()
        )
    }
}
