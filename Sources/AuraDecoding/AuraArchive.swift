public import Ion

public struct AuraArchive: Sendable {
    public let bodies: [Body]

    public init(bodies: [Body]) {
        self.bodies = bodies
    }
}
extension AuraArchive {
    public static var version: UInt32 { 2 }
}
extension AuraArchive {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case version
        case bodies
    }
}

extension AuraArchive: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.version] = Self.version
        ion[.bodies] = self.bodies
    }
}

extension AuraArchive: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        let version: Int = try ion[.version].decode()
        if  version != Self.version {
            throw VersionError.unsupported(version)
        }

        self.init(
            bodies: try ion[.bodies].decode()
        )
    }
}

extension AuraArchive {
    /// Serializes the archive as an uncompressed binary Ion archive.
    public func serialize() throws -> [UInt8] {
        let ion: Ion = .encode(atomic: self)
        return .init(ion.bytes)
    }

    /// Deserializes a AuraArchive from binary Ion bytes.
    public static func deserialize(from archive: [UInt8]) throws -> AuraArchive {
        let ion: Ion = .init(bytes: archive[...])
        return try ion.decode(atomic: Self.self)
    }
}
