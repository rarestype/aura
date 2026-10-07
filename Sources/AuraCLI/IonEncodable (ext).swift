import Ion
import SystemIO

extension IonEncodable {
    /// Serializes and writes the archive to the specified file path.
    func write(to path: FilePath) throws {
        let ion: Ion = .encode(atomic: self)
        try path.overwrite(with: ion.bytes)
    }
}
