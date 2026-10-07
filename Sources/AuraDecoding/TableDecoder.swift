public enum TableDecoder {}

extension TableDecoder {
    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer,
    /// returning reconstructed `SIMD4<Float>` texels.
    public static func decode(
        bytes: [UInt8],
        count: (x: Int, y: Int, z: Int)
    ) -> [SIMD4<Float>] {
        Self.decode(bytes: bytes, count: count, bpp: MemoryLayout<SIMD4<Float>>.stride)
    }

    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer,
    /// returning raw unmarshaled bytes.
    private static func decode(
        bytes: [UInt8],
        count: (x: Int, y: Int, z: Int),
        bpp: Int
    ) -> [SIMD4<Float>] {
        let volume: Int = count.x * count.y * count.z
        let pitch: Int = count.x * bpp

        precondition(
            bytes.count == volume * bpp,
            "Shuffled buffer is smaller than count.x * count.y * count.z * bpp"
        )

        return .init(unsafeUninitializedCapacity: volume) {
            let output: UnsafeMutableRawBufferPointer = .init($0)

            $1 = volume

            var i: Int = output.startIndex
            for z: Int in 0 ..< count.z {
                let start: Int = z * count.y * pitch
                for y: Int in 0 ..< count.y {
                    let start: Int = start + y * pitch
                    let prior: Int = start - pitch

                    if  y == 0 {
                        for x: Int in 0 ..< count.x {
                            let start: Int = start + x * bpp
                            for p: Int in 0 ..< bpp {
                                output[start + p] = bytes[p * volume + i]
                            }
                            i += 1
                        }
                    } else {
                        for x: Int in 0 ..< count.x {
                            let start: Int = start + x * bpp
                            let prior: Int = prior + x * bpp
                            for p: Int in 0 ..< bpp {
                                output[start + p] = output[prior + p] &+ bytes[p * volume + i]
                            }
                            i += 1
                        }
                    }
                }
            }
        }
    }
}
