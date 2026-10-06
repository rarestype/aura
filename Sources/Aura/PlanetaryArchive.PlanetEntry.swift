public import Ion

extension PlanetaryArchive {
    public struct PlanetEntry: Sendable, Equatable {
        public var name: String
        public var parameters: SurfaceParameters
        public var surface: SurfaceDescriptor
        public var atmosphere: AtmosphereDescriptor?

        public init(
            name: String,
            parameters: SurfaceParameters,
            surface: SurfaceDescriptor,
            atmosphere: AtmosphereDescriptor? = nil
        ) {
            self.name = name
            self.parameters = parameters
            self.surface = surface
            self.atmosphere = atmosphere
        }
    }
}

extension PlanetaryArchive.PlanetEntry {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case name
        case parameters
        case surface
        case atmosphere
    }
}

extension PlanetaryArchive.PlanetEntry: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.name] = self.name
        ion[.parameters] = self.parameters
        ion[.surface] = self.surface
        ion[.atmosphere] = self.atmosphere
    }
}

extension PlanetaryArchive.PlanetEntry: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            name: try ion[.name].decode(),
            parameters: try ion[.parameters].decode(),
            surface: try ion[.surface].decode(),
            atmosphere: try ion[.atmosphere]?.decode()
        )
    }
}
