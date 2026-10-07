public enum TableEncoder {}

extension TableEncoder {
    /// Applies PNG Up filtering and 16-plane byte shuffling to a `SIMD4<Float>` texel buffer.
    public static func encode(
        simd4: [SIMD4<Float>],
        count: (x: Int, y: Int, z: Int),
    ) -> [UInt8] {
        simd4.withUnsafeBytes {
            Self.encode(bytes: $0, count: count, stride: MemoryLayout<SIMD4<Float>>.stride)
        }
    }

    private static func encode(
        bytes: UnsafeRawBufferPointer,
        count: (x: Int, y: Int, z: Int),
        stride bpp: Int,
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
}
