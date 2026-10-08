import ArgumentParser
import Aura
import SystemIO

extension AuraArchive.Cubemap {
    static func load(
        optional directory: FilePath.Directory,
    ) throws -> Self? {
        guard try directory.exists else {
            return nil
        }
        return try .load(from: directory)
    }
    static func load(
        required directory: FilePath.Directory,
    ) throws -> Self {
        guard try directory.exists else {
            throw ValidationError.init("Texture directory not found: '\(directory)'")
        }
        return try .load(from: directory)
    }

    private static func load(
        from directory: FilePath.Directory,
    ) throws -> Self {
        .init(
            px: try (directory / "px.webp").read(),
            nx: try (directory / "nx.webp").read(),
            py: try (directory / "py.webp").read(),
            ny: try (directory / "ny.webp").read(),
            pz: try (directory / "pz.webp").read(),
            nz: try (directory / "nz.webp").read(),
        )
    }
}
