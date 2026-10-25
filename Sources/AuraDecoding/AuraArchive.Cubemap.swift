public import Ion

extension AuraArchive {
    public struct Cubemap: Sendable {
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

extension AuraArchive.Cubemap {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case px
        case nx
        case py
        case ny
        case pz
        case nz
    }
}

extension AuraArchive.Cubemap: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.px] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.px)
        ion[.nx] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.nx)
        ion[.py] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.py)
        ion[.ny] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.ny)
        ion[.pz] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.pz)
        ion[.nz] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.nz)
    }
}

extension AuraArchive.Cubemap: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        let px: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.px].decode()
        let nx: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.nx].decode()
        let py: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.py].decode()
        let ny: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.ny].decode()
        let pz: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.pz].decode()
        let nz: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.nz].decode()

        self.init(
            px: [_].init(px.bytes),
            nx: [_].init(nx.bytes),
            py: [_].init(py.bytes),
            ny: [_].init(ny.bytes),
            pz: [_].init(pz.bytes),
            nz: [_].init(nz.bytes)
        )
    }
}
