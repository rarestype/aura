public import AuraDecoding

extension Atmosphere.Table {
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
