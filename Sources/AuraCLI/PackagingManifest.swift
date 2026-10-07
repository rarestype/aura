import Aura
import Ion

struct PackagingManifest: Sendable {
    let output: String
    let bodies: [Body]

    public init(
        output: String,
        bodies: [Body]
    ) {
        self.output = output
        self.bodies = bodies
    }
}

extension PackagingManifest {
    enum CodingKey: String, IonSymbolizable {
        case output
        case bodies
    }
}

extension PackagingManifest: IonEncodableStruct {
    func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.output] = self.output
        ion[.bodies] = self.bodies
    }
}

extension PackagingManifest: IonDecodableStruct {
    init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            output: try ion[.output].decode(),
            bodies: try ion[.bodies].decode()
        )
    }
}
