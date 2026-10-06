import AuraDecoding
import LZ77

public enum TableCompression {
    /// Applies PNG Up filtering and 16-plane byte shuffling to a 2D or 3D buffer of raw bytes.
    public static func filterAndShuffle(
        bytes: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            Self.filterAndShuffle(
                raw: raw,
                width: width,
                height: height,
                depth: depth,
                bpp: bpp
            )
        }
    }

    /// Applies PNG Up filtering and 16-plane byte shuffling to a 2D or 3D slice of raw bytes.
    public static func filterAndShuffle(
        bytes: ArraySlice<UInt8>,
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            Self.filterAndShuffle(
                raw: raw,
                width: width,
                height: height,
                depth: depth,
                bpp: bpp
            )
        }
    }

    /// Applies PNG Up filtering and 16-plane byte shuffling to a 2D or 3D buffer.
    static func filterAndShuffle(
        raw: UnsafeRawBufferPointer,
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        let numPixels: Int = width * height * depth
        let totalBytes: Int = numPixels * bpp
        precondition(
            raw.count >= totalBytes,
            "Raw buffer is smaller than width * height * depth * bpp"
        )

        let rawBytes: UnsafePointer<UInt8> = raw.baseAddress!.assumingMemoryBound(
            to: UInt8.self
        )

        // 1. PNG Up filter along Y within each slice Z
        let rowBytes: Int = width * bpp
        var filtered: [UInt8] = .init(repeating: 0, count: totalBytes)

        filtered.withUnsafeMutableBufferPointer { (
                filteredPtr: inout UnsafeMutableBufferPointer<UInt8>
            ) in
            for z: Int in 0 ..< depth {
                let sliceOffset: Int = z * height * rowBytes

                // Row 0 of this slice: unchanged
                for b: Int in 0 ..< rowBytes {
                    filteredPtr[sliceOffset + b] = rawBytes[sliceOffset + b]
                }

                // Rows 1 ..< height: difference from preceding row
                for y: Int in 1 ..< height {
                    let rowOffset: Int = sliceOffset + y * rowBytes
                    let prevOffset: Int = rowOffset - rowBytes
                    for b: Int in 0 ..< rowBytes {
                        filteredPtr[
                            rowOffset + b
                        ] = rawBytes[rowOffset + b] &- rawBytes[prevOffset + b]
                    }
                }
            }
        }

        // 2. Byte shuffle: transpose from (numPixels, bpp) to (bpp, numPixels)
        var shuffled: [UInt8] = .init(repeating: 0, count: totalBytes)
        filtered.withUnsafeBufferPointer { (filteredPtr: UnsafeBufferPointer<UInt8>) in
            shuffled.withUnsafeMutableBufferPointer { (
                    shuffledPtr: inout UnsafeMutableBufferPointer<UInt8>
                ) in
                for p: Int in 0 ..< bpp {
                    let planeOffset: Int = p * numPixels
                    for i: Int in 0 ..< numPixels {
                        shuffledPtr[planeOffset + i] = filteredPtr[i * bpp + p]
                    }
                }
            }
        }

        return shuffled
    }

    /// Applies PNG Up filtering and 16-plane byte shuffling to a `SIMD4<Float>` texel buffer.
    public static func filterAndShuffle(
        simd4: [SIMD4<Float>],
        width: Int,
        height: Int,
        depth: Int = 1
    ) -> [UInt8] {
        simd4.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            Self.filterAndShuffle(raw: raw, width: width, height: height, depth: depth, bpp: 16)
        }
    }

    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer.
    public static func unshuffleAndUnfilter(
        shuffled: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        AtmosphereTableDecoder.decode(
            shuffled: shuffled,
            width: width,
            height: height,
            depth: depth,
            bpp: bpp
        )
    }

    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer
    /// returning `SIMD4<Float>` texels.
    public static func unshuffleAndUnfilter(
        shuffled: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1
    ) -> [SIMD4<Float>] {
        AtmosphereTableDecoder.decode(
            shuffled: shuffled,
            width: width,
            height: height,
            depth: depth
        )
    }

    /// Compresses data using Zlib (RFC 1950).
    public static func deflate(_ data: ArraySlice<UInt8>, level: Int = 7) -> [UInt8] {
        var deflator: LZ77.Deflator = .init(format: .zlib, level: level, hint: 128 << 10)
        deflator.push(data, last: true)
        var compressed: [UInt8] = []
        while let part: [UInt8] = deflator.pull() {
            compressed += part
        }
        return compressed
    }

    /// Compresses data using Zlib (RFC 1950).
    public static func deflate(_ data: [UInt8], level: Int = 7) -> [UInt8] {
        Self.deflate(data[...], level: level)
    }

    /// Decompresses data using Zlib (RFC 1950).
    public static func inflate(_ data: ArraySlice<UInt8>) throws -> [UInt8] {
        var inflator: LZ77.Inflator = .init(format: .zlib)
        _ = try inflator.push(data)
        return inflator.pull()
    }

    /// Decompresses data using Zlib (RFC 1950).
    public static func inflate(_ data: [UInt8]) throws -> [UInt8] {
        try Self.inflate(data[...])
    }

    /// Compresses a 2D or 3D volume buffer of raw bytes using PNG Up filtering,
    /// byte-plane shuffling, and Deflate compression.
    public static func compress(
        bytes: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            Self.compress(raw: raw, width: width, height: height, depth: depth, bpp: bpp)
        }
    }

    /// Compresses a 2D or 3D volume slice of raw bytes using PNG Up filtering,
    /// byte-plane shuffling, and Deflate compression.
    public static func compress(
        bytes: ArraySlice<UInt8>,
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            Self.compress(raw: raw, width: width, height: height, depth: depth, bpp: bpp)
        }
    }

    /// Compresses a 2D or 3D volume buffer using PNG Up filtering,
    /// byte-plane shuffling, and Deflate compression.
    internal static func compress(
        raw: UnsafeRawBufferPointer,
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        let shuffled: [UInt8] = Self.filterAndShuffle(
            raw: raw,
            width: width,
            height: height,
            depth: depth,
            bpp: bpp
        )
        return Self.deflate(shuffled[...], level: 7)
    }

    /// Compresses a buffer of `SIMD4<Float>` texels.
    public static func compress(
        simd4: [SIMD4<Float>],
        width: Int,
        height: Int,
        depth: Int = 1
    ) -> [UInt8] {
        simd4.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            Self.compress(raw: raw, width: width, height: height, depth: depth, bpp: 16)
        }
    }

    /// Decompresses an archive back into raw bytes, inverting byte shuffling and Up filtering.
    public static func decompress(
        archive: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) throws -> [UInt8] {
        let numPixels: Int = width * height * depth
        let totalBytes: Int = numPixels * bpp

        let shuffled: [UInt8] = try Self.inflate(archive[...])
        guard shuffled.count == totalBytes else {
            throw TableCompressionError.decompressedSizeMismatch(
                expected: totalBytes,
                actual: shuffled.count
            )
        }

        return Self.unshuffleAndUnfilter(
            shuffled: shuffled,
            width: width,
            height: height,
            depth: depth,
            bpp: bpp
        )
    }

    /// Decompresses an archive directly into an array of `SIMD4<Float>` texels.
    public static func decompress(
        archive: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1
    ) throws -> [SIMD4<Float>] {
        let numPixels: Int = width * height * depth
        let totalBytes: Int = numPixels * 16

        let shuffled: [UInt8] = try Self.inflate(archive[...])
        guard shuffled.count == totalBytes else {
            throw TableCompressionError.decompressedSizeMismatch(
                expected: totalBytes,
                actual: shuffled.count
            )
        }

        return Self.unshuffleAndUnfilter(
            shuffled: shuffled,
            width: width,
            height: height,
            depth: depth
        )
    }
}

@available(*, deprecated, renamed: "TableCompression")
public typealias AtmosphereCompression = TableCompression
