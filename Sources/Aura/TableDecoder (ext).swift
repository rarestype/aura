public import AuraDecoding
import LZ77

extension TableDecoder {
    /// Decompresses a buffer of `SIMD4<Float>` texels that was compressed using
    /// PNG Up filtering, 16-plane byte shuffling, and Deflate compression.
    public static func decompress(
        bytes compressed: [UInt8],
        count: (x: Int, y: Int, z: Int)
    ) throws -> [SIMD4<Float>] {
        var inflator: LZ77.Inflator = .init(format: .zlib)
        _ = try inflator.push(compressed[...])
        let shuffled: [UInt8] = inflator.pull()
        return Self.decode(bytes: shuffled, count: count)
    }
}
