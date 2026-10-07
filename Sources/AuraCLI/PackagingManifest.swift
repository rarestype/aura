import Aura
import Ion

struct PackagingManifest: Sendable {
    public static var currentVersion: UInt32 { 1 }

    public var version: UInt32
    public var output: String
    public var planets: [PlanetEntry]

    public init(
        version: UInt32 = Self.currentVersion,
        output: String,
        planets: [PlanetEntry]
    ) {
        self.version = version
        self.output = output
        self.planets = planets
    }
}

extension PackagingManifest {
    enum CodingKey: String, IonSymbolizable {
        case version
        case output
        case planets
    }
}

extension PackagingManifest: IonEncodableStruct {
    func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.version] = self.version
        ion[.output] = self.output
        ion[.planets] = self.planets
    }
}

extension PackagingManifest: IonDecodableStruct {
    init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            version: try ion[.version].decode(),
            output: try ion[.output].decode(),
            planets: try ion[.planets].decode()
        )
    }
}
