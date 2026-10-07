import Aura
import Ion

extension PackagingManifest {
    struct PlanetEntry: Sendable {
        public var name: String
        public var textures: String
        public var spheroid: AuraArchive.Spheroid
        public var atmosphere: String?

        public init(
            name: String,
            textures: String,
            spheroid: AuraArchive.Spheroid,
            atmosphere: String? = nil
        ) {
            self.name = name
            self.textures = textures
            self.spheroid = spheroid
            self.atmosphere = atmosphere
        }
    }
}

extension PackagingManifest.PlanetEntry {
    enum CodingKey: String, IonSymbolizable {
        case name
        case textures
        case spheroid
        case atmosphere
    }
}

extension PackagingManifest.PlanetEntry: IonEncodableStruct {
    func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.name] = self.name
        ion[.textures] = self.textures
        ion[.spheroid] = self.spheroid
        ion[.atmosphere] = self.atmosphere
    }
}

extension PackagingManifest.PlanetEntry: IonDecodableStruct {
    init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            name: try ion[.name].decode(),
            textures: try ion[.textures].decode(),
            spheroid: try ion[.spheroid].decode(),
            atmosphere: try ion[.atmosphere]?.decode()
        )
    }
}
