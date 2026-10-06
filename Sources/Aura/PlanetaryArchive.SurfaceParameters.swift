public import Ion

extension PlanetaryArchive {
    public struct SurfaceParameters: Sendable, Equatable {
        public var radius: Double
        public var tilt: Double
        public var flattening: Double
        public var reliefScale: Double

        public init(
            radius: Double = 1.0,
            tilt: Double = 0.0,
            flattening: Double = 0.0,
            reliefScale: Double = 1.0
        ) {
            self.radius = radius
            self.tilt = tilt
            self.flattening = flattening
            self.reliefScale = reliefScale
        }
    }
}

extension PlanetaryArchive.SurfaceParameters {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case radius
        case tilt
        case flattening
        case relief_scale
    }
}

extension PlanetaryArchive.SurfaceParameters: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.radius] = self.radius
        ion[.tilt] = self.tilt
        ion[.flattening] = self.flattening
        ion[.relief_scale] = self.reliefScale
    }
}

extension PlanetaryArchive.SurfaceParameters: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            radius: try ion[.radius]?.decode() ?? 1.0,
            tilt: try ion[.tilt]?.decode() ?? 0.0,
            flattening: try ion[.flattening]?.decode() ?? 0.0,
            reliefScale: try ion[.relief_scale]?.decode() ?? 1.0
        )
    }
}
