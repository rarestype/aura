public import AuraEncoding
import LZ77

extension TableEncoder {
    /// Compresses a buffer of `SIMD4<Float>` texels using PNG Up filtering,
    /// 16-plane byte shuffling, and Deflate compression.
    public static func compress(
        simd4: [SIMD4<Float>],
        count: (x: Int, y: Int, z: Int),
        level: Int = 7
    ) -> [UInt8] {
        let bytes: [UInt8] = Self.encode(simd4: simd4, count: count)
        var deflator: LZ77.Deflator = .init(format: .zlib, level: level, hint: 128 << 10)
        ;   deflator.push(bytes[...], last: true)
        var compressed: [UInt8] = []
        while let part: [UInt8] = deflator.pull() {
            compressed += part
        }
        return compressed
    }
}
