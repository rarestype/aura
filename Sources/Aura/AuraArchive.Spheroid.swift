public import Ion

extension AuraArchive {
    public struct Spheroid: Sendable {
        public var radius: Double
        public var relief: Double
        public var tilt: Double
        public var flattening: Double

        public init(
            radius: Double,
            relief: Double,
            tilt: Double,
            flattening: Double,
        ) {
            self.radius = radius
            self.relief = relief
            self.tilt = tilt
            self.flattening = flattening
        }
    }
}

extension AuraArchive.Spheroid {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case radius
        case relief
        case tilt
        case flattening
    }
}

extension AuraArchive.Spheroid: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.radius] = self.radius
        ion[.relief] = self.relief
        ion[.tilt] = self.tilt
        ion[.flattening] = self.flattening
    }
}

extension AuraArchive.Spheroid: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            radius: try ion[.radius].decode(),
            relief: try ion[.relief].decode(),
            tilt: try ion[.tilt].decode(),
            flattening: try ion[.flattening].decode(),
        )
    }
}
