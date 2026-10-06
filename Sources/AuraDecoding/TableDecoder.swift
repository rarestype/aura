public enum TableDecoder {}

extension TableDecoder {
    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer,
    /// returning reconstructed `SIMD4<Float>` texels.
    @inlinable public static func decode(
        shuffled: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1
    ) -> [SIMD4<Float>] {
        let bytes: [UInt8] = Self.decode(
            shuffled: shuffled,
            width: width,
            height: height,
            depth: depth,
            bpp: 16
        )
        let pixelCount: Int = width * height * depth
        return bytes.withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            let bound: UnsafeBufferPointer<SIMD4<Float>> = raw.bindMemory(to: SIMD4<Float>.self)
            return .init(bound.prefix(pixelCount))
        }
    }

    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer,
    /// returning raw unmarshaled bytes.
    @inlinable public static func decode(
        shuffled: [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) -> [UInt8] {
        let pixelCount: Int = width * height * depth
        let totalBytes: Int = pixelCount * bpp
        precondition(
            shuffled.count >= totalBytes,
            "Shuffled buffer is smaller than width * height * depth * bpp"
        )

        var output: [UInt8] = .init(repeating: 0, count: totalBytes)
        shuffled.withUnsafeBufferPointer { (shuffledPointer: UnsafeBufferPointer<UInt8>) in
            output.withUnsafeMutableBufferPointer { (outputPointer: inout UnsafeMutableBufferPointer<UInt8>) in
                Self.decode(
                    shuffled: shuffledPointer,
                    into: outputPointer,
                    width: width,
                    height: height,
                    depth: depth,
                    bpp: bpp
                )
            }
        }
        return output
    }

    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer
    /// directly into a destination buffer.
    @inlinable public static func decode(
        shuffled: [UInt8],
        into output: inout [UInt8],
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) {
        let pixelCount: Int = width * height * depth
        let totalBytes: Int = pixelCount * bpp
        precondition(
            shuffled.count >= totalBytes,
            "Shuffled buffer is smaller than width * height * depth * bpp"
        )
        precondition(
            output.count >= totalBytes,
            "Output buffer is smaller than width * height * depth * bpp"
        )

        shuffled.withUnsafeBufferPointer { (shuffledPointer: UnsafeBufferPointer<UInt8>) in
            output.withUnsafeMutableBufferPointer { (outputPointer: inout UnsafeMutableBufferPointer<UInt8>) in
                Self.decode(
                    shuffled: shuffledPointer,
                    into: outputPointer,
                    width: width,
                    height: height,
                    depth: depth,
                    bpp: bpp
                )
            }
        }
    }

    /// Inverts byte plane shuffling and PNG Up filtering on a preprocessed buffer
    /// directly into a `SIMD4<Float>` destination buffer.
    @inlinable public static func decode(
        shuffled: [UInt8],
        into output: inout [SIMD4<Float>],
        width: Int,
        height: Int,
        depth: Int = 1
    ) {
        let pixelCount: Int = width * height * depth
        let totalBytes: Int = pixelCount * 16
        precondition(
            shuffled.count >= totalBytes,
            "Shuffled buffer is smaller than width * height * depth * 16"
        )
        precondition(
            output.count >= pixelCount,
            "Output buffer is smaller than width * height * depth"
        )

        output.withUnsafeMutableBytes { (outputRaw: UnsafeMutableRawBufferPointer) in
            let outputPointer: UnsafeMutableBufferPointer<UInt8> = outputRaw.bindMemory(to: UInt8.self)
            shuffled.withUnsafeBufferPointer { (shuffledPointer: UnsafeBufferPointer<UInt8>) in
                Self.decode(
                    shuffled: shuffledPointer,
                    into: outputPointer,
                    width: width,
                    height: height,
                    depth: depth,
                    bpp: 16
                )
            }
        }
    }

    /// Inverts byte plane shuffling and PNG Up filtering directly into a destination buffer.
    @usableFromInline internal static func decode(
        shuffled: UnsafeBufferPointer<UInt8>,
        into output: UnsafeMutableBufferPointer<UInt8>,
        width: Int,
        height: Int,
        depth: Int = 1,
        bpp: Int = 16
    ) {
        let pixelCount: Int = width * height * depth
        let rowBytes: Int = width * bpp

        var pixelIndex: Int = 0
        for z: Int in 0 ..< depth {
            let sliceOffset: Int = z * height * rowBytes
            for y: Int in 0 ..< height {
                let rowOffset: Int = sliceOffset + y * rowBytes
                let previousRowOffset: Int = rowOffset - rowBytes

                if y == 0 {
                    for x: Int in 0 ..< width {
                        let pixelOffset: Int = rowOffset + x * bpp
                        for p: Int in 0 ..< bpp {
                            output[pixelOffset + p] = shuffled[p * pixelCount + pixelIndex]
                        }
                        pixelIndex += 1
                    }
                } else {
                    for x: Int in 0 ..< width {
                        let pixelOffset: Int = rowOffset + x * bpp
                        let previousPixelOffset: Int = previousRowOffset + x * bpp
                        for p: Int in 0 ..< bpp {
                            output[
                                pixelOffset + p
                            ] = output[previousPixelOffset + p] &+ shuffled[p * pixelCount + pixelIndex]
                        }
                        pixelIndex += 1
                    }
                }
            }
        }
    }
}
