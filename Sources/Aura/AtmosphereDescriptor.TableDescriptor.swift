import AuraDecoding
public import Ion
import LZ77

extension AtmosphereDescriptor {
    public struct TableDescriptor: Sendable {
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

extension AtmosphereDescriptor.TableDescriptor {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case width
        case height
        case depth
        case data
    }
}

extension AtmosphereDescriptor.TableDescriptor: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.width] = self.width
        ion[.height] = self.height
        ion[.depth] = self.depth
        ion[.data] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.data)
    }
}

extension AtmosphereDescriptor.TableDescriptor: IonDecodableStruct {
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

extension AtmosphereDescriptor.TableDescriptor {
    /// Decompresses and un-filters byte-shuffled data into reconstructed texels.
    public func decode() throws -> [SIMD4<Float>] {
        let depth: Int = self.depth ?? 1
        let numPixels: Int = self.width * self.height * depth
        let totalBytes: Int = numPixels * 16

        var inflator: LZ77.Inflator = .init(format: .zlib)
        _ = try inflator.push(self.data[...])
        let shuffled: [UInt8] = inflator.pull()

        guard shuffled.count == totalBytes else {
            throw DecompressionError.decompressedSizeMismatch(
                expected: totalBytes,
                actual: shuffled.count
            )
        }

        return TableDecoder.decode(
            shuffled: shuffled,
            width: self.width,
            height: self.height,
            depth: depth
        )
    }
}
