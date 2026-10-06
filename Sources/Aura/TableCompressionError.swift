public enum TableCompressionError: Swift.Error, Sendable, Equatable {
    case decompressedSizeMismatch(expected: Int, actual: Int)
}

@available(*, deprecated, renamed: "TableCompressionError")
public typealias AtmosphereCompressionError = TableCompressionError
