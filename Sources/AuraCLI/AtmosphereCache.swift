import Aura
import Ion
import SHA2
import SystemIO

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// The baked atmospheres that `aura pack` keeps, so that it only bakes an atmosphere again
/// when its configuration, its level of detail, or aura itself changes.
///
/// Each bake is stored under a key that hashes everything the bake depends on: the
/// configuration, the level of detail, and the aura executable that baked it. Changing any of
/// them changes the key, so the cache never returns a stale bake, and it only ever needs to
/// be cleared to reclaim space. The number of threads is not part of the key, because it
/// does not change what a bake produces.
struct AtmosphereCache {
    let directory: FilePath.Directory
    /// The digest of the running aura executable, which stands for the solver that bakes the
    /// atmospheres.
    let executable: SHA256

    init(directory: FilePath.Directory, executable: SHA256) {
        self.directory = directory
        self.executable = executable
    }
}
extension AtmosphereCache {
    /// The cache that the environment selects, or nil if the cache is off, or if aura cannot
    /// find its own executable, which it needs in order to tell the bakes of different builds
    /// of itself apart.
    static func current() throws -> Self? {
        guard
        let directory: FilePath.Directory = Self.location else {
            print("The atmosphere cache is off, so atmospheres are baked every time.")
            return nil
        }
        guard
        let executable: SHA256 = try Self.digest() else {
            print("Cannot find the aura executable, so atmospheres are baked every time.")
            return nil
        }
        return .init(directory: directory, executable: executable)
    }

    /// The directory of the cache, or nil if the environment variable `AURA_CACHE` is `off`.
    ///
    /// `AURA_CACHE` can also name the directory itself. Otherwise, the cache is
    /// `aura/atmospheres` in the user’s cache directory, which is `$XDG_CACHE_HOME` or
    /// `~/.cache`, or `~/Library/Caches` on macOS.
    static var location: FilePath.Directory? {
        switch Environment["AURA_CACHE"] as String? {
        case "off"?:
            return nil

        case let path? where !path.isEmpty:
            return .init(path)

        default:
            break
        }

        let root: FilePath.Directory
        #if os(macOS)
        guard
        let home: String = Environment["HOME"] else {
            return nil
        }
        root = .init(home) / "Library" / "Caches"
        #else
        if  let cache: String = Environment["XDG_CACHE_HOME"], !cache.isEmpty {
            root = .init(cache)
        } else if
            let home: String = Environment["HOME"] {
            root = .init(home) / ".cache"
        } else {
            return nil
        }
        #endif

        return root / "aura" / "atmospheres"
    }

    /// Hashes the running executable, or returns nil if its path cannot be found.
    private static func digest() throws -> SHA256? {
        #if canImport(Darwin)
        var size: UInt32 = 0
        _ = _NSGetExecutablePath(nil, &size)
        var buffer: [CChar] = .init(repeating: 0, count: Int.init(size))
        guard case 0 = _NSGetExecutablePath(&buffer, &size) else {
            return nil
        }
        let path: FilePath = buffer.withUnsafeBufferPointer {
            .init(platformString: $0.baseAddress!)
        }
        #else
        // a link to the executable that is running
        let path: FilePath = "/proc/self/exe"
        #endif

        return .init(hashing: try path.read([UInt8].self))
    }
}
extension AtmosphereCache {
    /// Returns the bake of `body` at the level of `detail`, from the cache if it is there,
    /// or else baking it with `workers` threads, and adding it to the cache.
    ///
    /// A bake is written to a temporary file first, and then renamed, so an interrupted bake
    /// leaves nothing in the cache. An entry that cannot be read is baked again.
    func atmosphere(
        for body: AtmosphereConfiguration,
        detail: Int,
        workers: Int
    ) async throws -> AtmosphereArchive {
        let path: FilePath = self.directory / "\(self.key(for: body, detail: detail)).atmo"

        if  try path.exists {
            do {
                let file: Ion = .init(bytes: try path.read()[...])
                let archive: AtmosphereArchive = try file.decode()
                print("Using the cached atmosphere for '\(body.name)' from '\(path)'")
                return archive
            } catch let error {
                print(
                    "Cannot read the cached atmosphere at '\(path)', baking it again: \(error)"
                )
            }
        }

        print("Baking the atmosphere for '\(body.name)' (detail: \(detail)) into '\(path)'...")
        let archive: AtmosphereArchive = await .bake(body, detail: detail, workers: workers)

        try self.directory.create()
        let partial: FilePath = self.directory / """
        \(path.stem ?? "atmosphere").\(getpid()).partial
        """
        try archive.write(to: partial)
        try Self.move(partial, to: path)
        return archive
    }

    /// Hashes the digest of the executable, the level of detail, and the binary encoding of
    /// the configuration, so that editing a comment or the formatting of a configuration does
    /// not change its key.
    private func key(for body: AtmosphereConfiguration, detail: Int) -> SHA256 {
        var message: [UInt8] = []
        message += self.executable
        withUnsafeBytes(of: Int64.init(detail).littleEndian) { message += $0 }
        message += Ion.encode(atomic: body).bytes
        return .init(hashing: message)
    }

    /// Renames `source` to `destination`, replacing it if it exists, which happens all at
    /// once, so that no one ever reads half of `destination`.
    private static func move(_ source: FilePath, to destination: FilePath) throws {
        let status: Int32 = source.withPlatformString { (source: UnsafePointer<CChar>) in
            destination.withPlatformString { rename(source, $0) }
        }
        guard case 0 = status else {
            throw MoveError.init(source: source, destination: destination, code: errno)
        }
    }
}
