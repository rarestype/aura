public enum AtmosphereArchiveError: Swift.Error, Sendable, Equatable {
    case unsupportedVersion(UInt32)
    case tableNotFound(String)
    case planetNotFound(String)
}
