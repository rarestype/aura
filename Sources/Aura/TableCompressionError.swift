public enum TableCompressionError: Error {
    case decompressedSizeMismatch(expected: Int, actual: Int)
}

@available(*, deprecated, renamed: "TableCompressionError")
public typealias AtmosphereCompressionError = TableCompressionError
