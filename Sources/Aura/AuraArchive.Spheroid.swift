public import Ion

extension AuraArchive {
    public struct Spheroid: Sendable {
        public var radius: Double
        public var tilt: Double
        public var flattening: Double
        public var reliefScale: Double

        public init(
            radius: Double,
            tilt: Double,
            flattening: Double,
            reliefScale: Double
        ) {
            self.radius = radius
            self.tilt = tilt
            self.flattening = flattening
            self.reliefScale = reliefScale
        }
    }
}

extension AuraArchive.Spheroid {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case radius
        case tilt
        case flattening
        case relief_scale
    }
}

extension AuraArchive.Spheroid: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.radius] = self.radius
        ion[.tilt] = self.tilt
        ion[.flattening] = self.flattening
        ion[.relief_scale] = self.reliefScale
    }
}

extension AuraArchive.Spheroid: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            radius: try ion[.radius].decode(),
            tilt: try ion[.tilt].decode(),
            flattening: try ion[.flattening].decode(),
            reliefScale: try ion[.relief_scale].decode()
        )
    }
}
