enum AtmosphereCompressionError: Error {
    case decompressedSizeMismatch(expected: Int, actual: Int)
}
