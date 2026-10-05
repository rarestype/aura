extension AtmosphereArchive {
    public enum Error: Swift.Error, Sendable {
        case invalidMagic
        case unsupportedVersion(UInt32)
        case corruptHeader
        case corruptManifest
        case planetNotFound(String)
        case tableNotFound(String)
        case bufferOutOfBounds
    }
}
