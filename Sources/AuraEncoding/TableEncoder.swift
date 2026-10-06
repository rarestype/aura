import LZ77

public enum TableEncoder {}

extension TableEncoder {
    /// Applies PNG Up filtering and byte shuffling to a 2D or 3D buffer.
    private static func filterAndShuffle(
        raw: UnsafeRawBufferPointer,
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        let pixelCount: Int = width * height * depth
        let totalBytes: Int = pixelCount * bpp
        precondition(
            raw.count >= totalBytes,
            "Raw buffer is smaller than width * height * depth * bpp"
        )

        let rawPointer: UnsafePointer<UInt8> = raw.baseAddress!.assumingMemoryBound(
            to: UInt8.self
        )

        // 1. PNG Up filter along Y within each slice Z
        let rowBytes: Int = width * bpp
        var filtered: [UInt8] = .init(repeating: 0, count: totalBytes)

        filtered.withUnsafeMutableBufferPointer { (
                filteredPointer: inout UnsafeMutableBufferPointer<UInt8>
            ) in
            for z: Int in 0 ..< depth {
                let sliceOffset: Int = z * height * rowBytes

                // Row 0 of this slice: unchanged
                for b: Int in 0 ..< rowBytes {
                    filteredPointer[sliceOffset + b] = rawPointer[sliceOffset + b]
                }

                // Rows 1 ..< height: difference from preceding row
                for y: Int in 1 ..< height {
                    let rowOffset: Int = sliceOffset + y * rowBytes
                    let prevOffset: Int = rowOffset - rowBytes
                    for b: Int in 0 ..< rowBytes {
                        filteredPointer[
                            rowOffset + b
                        ] = rawPointer[rowOffset + b] &- rawPointer[prevOffset + b]
                    }
                }
            }
        }

        // 2. Byte shuffle: transpose from (pixelCount, bpp) to (bpp, pixelCount)
        var shuffled: [UInt8] = .init(repeating: 0, count: totalBytes)
        filtered.withUnsafeBufferPointer { (filteredPointer: UnsafeBufferPointer<UInt8>) in
            shuffled.withUnsafeMutableBufferPointer { (
                    shuffledPointer: inout UnsafeMutableBufferPointer<UInt8>
                ) in
                for p: Int in 0 ..< bpp {
                    let planeOffset: Int = p * pixelCount
                    for i: Int in 0 ..< pixelCount {
                        shuffledPointer[planeOffset + i] = filteredPointer[i * bpp + p]
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

    /// Compresses a 2D or 3D volume buffer of raw bytes using PNG Up filtering,
    /// byte-plane shuffling, and Deflate compression.
    public static func compress(
        bytes: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16,
        level: Int = 7
    ) -> [UInt8] {
        let shuffled: [UInt8] = bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            Self.filterAndShuffle(raw: raw, width: width, height: height, depth: depth, bpp: bpp)
        }
        return Self.deflate(shuffled[...], level: level)
    }

    /// Compresses a buffer of `SIMD4<Float>` texels using PNG Up filtering,
    /// 16-plane byte shuffling, and Deflate compression.
    public static func compress(
        simd4: [SIMD4<Float>],
        width: Int,
        height: Int,
        depth: Int = 1,
        level: Int = 7
    ) -> [UInt8] {
        let shuffled: [UInt8] = Self.filterAndShuffle(
            simd4: simd4,
            width: width,
            height: height,
            depth: depth
        )
        return Self.deflate(shuffled[...], level: level)
    }
}
