import AuraDecoding
public import Ion
import LZ77

extension Atmosphere {
    @frozen public struct Table: Sendable {
        public let x: Int
        public let y: Int
        public let z: Int
        public let bytes: [UInt8]

        @inlinable public init(
            x: Int,
            y: Int,
            z: Int,
            bytes: [UInt8]
        ) {
            self.x = x
            self.y = y
            self.z = z
            self.bytes = bytes
        }
    }
}
extension Atmosphere.Table {
    @inlinable public var volume: Int { self.x * self.y * self.z }

    /// Decompresses and un-filters byte-shuffled data into reconstructed texels.
    public func decompress() throws -> [SIMD4<Float>] {
        let pixels: [SIMD4<Float>] = try TableDecoder.decompress(
            bytes: self.bytes,
            count: (self.x, self.y, self.z)
        )

        guard self.volume == pixels.count else {
            throw Atmosphere.TableError.size(
                expected: (self.x, self.y, self.z),
                actual: pixels.count
            )
        }

        return pixels
    }
}

extension Atmosphere.Table {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case x
        case y
        case z
        case bytes
    }
}
extension Atmosphere.Table: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.x] = self.x
        ion[.y] = self.y
        ion[.z] = self.z == 1 ? nil : self.z
        ion[.bytes] = Ion.BlobView<[UInt8], Ion.BlobType>.init(bytes: self.bytes)
    }
}
extension Atmosphere.Table: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        let x: Int = try ion[.x].decode()
        let y: Int = try ion[.y].decode()
        let z: Int = try ion[.z]?.decode() ?? 1
        let blob: Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType> = try ion[.bytes].decode()
        self.init(
            x: x,
            y: y,
            z: z,
            bytes: [_].init(blob.bytes)
        )
    }
}
