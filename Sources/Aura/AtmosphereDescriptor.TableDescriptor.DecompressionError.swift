extension AtmosphereDescriptor.TableDescriptor {
    public enum DecompressionError: Error, Sendable, Equatable {
        case decompressedSizeMismatch(expected: Int, actual: Int)
    }
}
