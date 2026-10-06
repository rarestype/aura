public import Ion

extension PlanetaryArchive {
    public struct CubemapFaces: Sendable, Equatable {
        public var px: [UInt8]
        public var nx: [UInt8]
        public var py: [UInt8]
        public var ny: [UInt8]
        public var pz: [UInt8]
        public var nz: [UInt8]

        public init(
            px: [UInt8],
            nx: [UInt8],
            py: [UInt8],
            ny: [UInt8],
            pz: [UInt8],
            nz: [UInt8]
        ) {
            self.px = px
            self.nx = nx
            self.py = py
            self.ny = ny
            self.pz = pz
            self.nz = nz
        }
    }
}

extension PlanetaryArchive.CubemapFaces {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case px
        case nx
        case py
        case ny
        case pz
        case nz
    }
}

extension PlanetaryArchive.CubemapFaces: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.px] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.px)
        ion[.nx] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.nx)
        ion[.py] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.py)
        ion[.ny] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.ny)
        ion[.pz] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.pz)
        ion[.nz] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.nz)
    }
}

extension PlanetaryArchive.CubemapFaces: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        let pxBlob: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.px].decode()
        let nxBlob: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.nx].decode()
        let pyBlob: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.py].decode()
        let nyBlob: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.ny].decode()
        let pzBlob: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.pz].decode()
        let nzBlob: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.nz].decode()

        self.init(
            px: .init(pxBlob.bytes),
            nx: .init(nxBlob.bytes),
            py: .init(pyBlob.bytes),
            ny: .init(nyBlob.bytes),
            pz: .init(pzBlob.bytes),
            nz: .init(nzBlob.bytes)
        )
    }
}
