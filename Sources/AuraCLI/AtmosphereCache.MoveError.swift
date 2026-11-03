import SystemIO

extension AtmosphereCache {
    /// A bake could not be moved into the cache.
    struct MoveError: Error {
        let source: FilePath
        let destination: FilePath
        /// The `errno` that `rename` failed with.
        let code: Int32

        init(source: FilePath, destination: FilePath, code: Int32) {
            self.source = source
            self.destination = destination
            self.code = code
        }
    }
}
extension AtmosphereCache.MoveError: CustomStringConvertible {
    var description: String {
        "cannot move '\(self.source)' to '\(self.destination)' (errno \(self.code))"
    }
}
