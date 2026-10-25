extension AuraArchive {
    enum VersionError: Error {
        case unsupported(Int)
    }
}
extension AuraArchive.VersionError: CustomStringConvertible {
    var description: String {
        switch self {
        case .unsupported(let version):
            "unsupported aura archive version: \(version)"
        }
    }
}
