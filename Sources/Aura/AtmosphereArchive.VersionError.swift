extension AtmosphereArchive {
    enum VersionError: Error {
        case unsupported(Int)
    }
}
extension AtmosphereArchive.VersionError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unsupported(let version):
            "unsupported atmosphere archive version: \(version)"
        }
    }
}
