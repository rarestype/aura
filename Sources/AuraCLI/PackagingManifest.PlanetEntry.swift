import Aura
import Ion

extension PackagingManifest {
    struct PlanetEntry: Sendable {
        public var name: String
        public var textures: String
        public var atmosphere: String?
        public var parameters: PlanetaryArchive.SurfaceParameters

        public init(
            name: String,
            textures: String,
            atmosphere: String? = nil,
            parameters: PlanetaryArchive.SurfaceParameters
        ) {
            self.name = name
            self.textures = textures
            self.atmosphere = atmosphere
            self.parameters = parameters
        }
    }
}

extension PackagingManifest.PlanetEntry {
    enum CodingKey: String, IonSymbolizable {
        case name
        case textures
        case atmosphere
        case parameters
    }
}

extension PackagingManifest.PlanetEntry: IonEncodableStruct {
    func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.name] = self.name
        ion[.textures] = self.textures
        ion[.atmosphere] = self.atmosphere
        ion[.parameters] = self.parameters
    }
}

extension PackagingManifest.PlanetEntry: IonDecodableStruct {
    init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            name: try ion[.name].decode(),
            textures: try ion[.textures].decode(),
            atmosphere: try ion[.atmosphere]?.decode(),
            parameters: try ion[.parameters].decode()
        )
    }
}
