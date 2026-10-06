public import Ion

extension PlanetaryArchive {
    public struct SurfaceDescriptor: Sendable, Equatable {
        public var albedo: CubemapFaces
        public var relief: CubemapFaces?

        public init(
            albedo: CubemapFaces,
            relief: CubemapFaces? = nil
        ) {
            self.albedo = albedo
            self.relief = relief
        }
    }
}

extension PlanetaryArchive.SurfaceDescriptor {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case albedo
        case relief
    }
}

extension PlanetaryArchive.SurfaceDescriptor: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.albedo] = self.albedo
        ion[.relief] = self.relief
    }
}

extension PlanetaryArchive.SurfaceDescriptor: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            albedo: try ion[.albedo].decode(),
            relief: try ion[.relief]?.decode()
        )
    }
}
