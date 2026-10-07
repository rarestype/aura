public import Ion

extension AuraArchive {
    public struct Body: Sendable {
        public let name: String
        public var spheroid: Spheroid
        public var albedo: Cubemap
        public var relief: Cubemap?
        public var atmosphere: AtmosphereDescriptor?

        public init(
            name: String,
            spheroid: Spheroid,
            albedo: Cubemap,
            relief: Cubemap? = nil,
            atmosphere: AtmosphereDescriptor? = nil
        ) {
            self.name = name
            self.spheroid = spheroid
            self.albedo = albedo
            self.relief = relief
            self.atmosphere = atmosphere
        }
    }
}

extension AuraArchive.Body {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case name
        case spheroid
        case albedo
        case relief
        case atmosphere
    }
}
extension AuraArchive.Body: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.name] = self.name
        ion[.spheroid] = self.spheroid
        ion[.albedo] = self.albedo
        ion[.relief] = self.relief
        ion[.atmosphere] = self.atmosphere
    }
}
extension AuraArchive.Body: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            name: try ion[.name].decode(),
            spheroid: try ion[.spheroid].decode(),
            albedo: try ion[.albedo].decode(),
            relief: try ion[.relief]?.decode(),
            atmosphere: try ion[.atmosphere]?.decode()
        )
    }
}
