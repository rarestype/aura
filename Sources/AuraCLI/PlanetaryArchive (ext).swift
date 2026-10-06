import Aura
import SystemIO
public import SystemPackage

extension PlanetaryArchive {
    /// Serializes and writes the archive to the specified file path.
    public func write(to path: FilePath) throws {
        let bytes: [UInt8] = try self.serialize()
        try path.overwrite(with: bytes[...])
    }
}
