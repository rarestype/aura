public import Ion

extension AtmosphereArchive {
    public struct TableDescriptor: Sendable, Equatable {
        public var width: Int
        public var height: Int
        public var depth: Int?
        public var data: [UInt8]

        public init(
            width: Int,
            height: Int,
            depth: Int? = nil,
            data: [UInt8]
        ) {
            self.width = width
            self.height = height
            self.depth = depth
            self.data = data
        }
    }
}

extension AtmosphereArchive.TableDescriptor {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case width
        case height
        case depth
        case data
    }
}

extension AtmosphereArchive.TableDescriptor: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.width] = self.width
        ion[.height] = self.height
        ion[.depth] = self.depth
        ion[.data] = Ion.BlobView<[UInt8], Ion.BlobType>(bytes: self.data)
    }
}

extension AtmosphereArchive.TableDescriptor: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        let width: Int = try ion[.width].decode()
        let height: Int = try ion[.height].decode()
        let depth: Int? = try ion[.depth]?.decode()
        let blob: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.data].decode()
        self.init(
            width: width,
            height: height,
            depth: depth,
            data: .init(blob.bytes)
        )
    }
}
