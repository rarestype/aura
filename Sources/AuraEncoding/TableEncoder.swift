import LZ77

public enum TableEncoder {}

extension TableEncoder {
    /// Compresses a buffer of `SIMD4<Float>` texels using PNG Up filtering,
    /// 16-plane byte shuffling, and Deflate compression.
    public static func compress(
        simd4: [SIMD4<Float>],
        count: (x: Int, y: Int, z: Int),
        level: Int = 7
    ) -> [UInt8] {
        let shuffled: [UInt8] = Self.encode(simd4: simd4, count: count)
        return Self.deflate(shuffled[...], level: level)
    }
}
extension TableEncoder {
    /// Applies PNG Up filtering and 16-plane byte shuffling to a `SIMD4<Float>` texel buffer.
    public static func encode(
        simd4: [SIMD4<Float>],
        count: (x: Int, y: Int, z: Int),
    ) -> [UInt8] {
        simd4.withUnsafeBytes { Self.encode(bytes: $0, count: count, stride: 16) }
    }

    private static func encode(
        bytes: UnsafeRawBufferPointer,
        count: (x: Int, y: Int, z: Int),
        stride bpp: Int = 16
    ) -> [UInt8] {
        let volume: Int = count.x * count.y * count.z

        precondition(
            bytes.count >= volume * bpp,
            "Raw buffer is smaller than width * height * depth * bpp"
        )

        // PNG Up filter along Y within each slice Z
        let pitch: Int = count.x * bpp
        let filtered: [UInt8] = .init(unsafeUninitializedCapacity: bytes.count) {
            for z: Int in 0 ..< count.z {
                let start: Int = z * count.y * pitch

                // Row 0 of this slice: unchanged
                for b: Int in 0 ..< pitch {
                    $0[start + b] = bytes[start + b]
                }

                // Rows 1 ..< height: difference from preceding row
                for y: Int in 1 ..< count.y {
                    let start: Int = start + y * pitch
                    let prior: Int = start - pitch
                    for b: Int in 0 ..< pitch {
                        $0[start + b] = bytes[start + b] &- bytes[prior + b]
                    }
                }
            }

            $1 = bytes.count
        }

        // Byte shuffle: transpose from (volume, bpp) to (bpp, volume)
        return .init(unsafeUninitializedCapacity: bytes.count) {
            for p: Int in 0 ..< bpp {
                let start: Int = p * volume
                for i: Int in 0 ..< volume {
                    $0[start + i] = filtered[i * bpp + p]
                }
            }

            $1 = bytes.count
        }
    }

    /// Compresses data using Zlib (RFC 1950).
    private static func deflate(_ data: ArraySlice<UInt8>, level: Int) -> [UInt8] {
        var deflator: LZ77.Deflator = .init(format: .zlib, level: level, hint: 128 << 10)
        ;   deflator.push(data, last: true)
        var compressed: [UInt8] = []
        while let part: [UInt8] = deflator.pull() {
            compressed += part
        }
        return compressed
    }
}
