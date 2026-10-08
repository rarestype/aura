import Aura
import Ion

struct PackagingManifest: Sendable {
    let bodies: [Body]

    public init(
        bodies: [Body]
    ) {
        self.bodies = bodies
    }
}

extension PackagingManifest {
    enum CodingKey: String, IonSymbolizable {
        case bodies
    }
}

extension PackagingManifest: IonEncodableStruct {
    func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.bodies] = self.bodies
    }
}

extension PackagingManifest: IonDecodableStruct {
    init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            bodies: try ion[.bodies].decode()
        )
    }
}
