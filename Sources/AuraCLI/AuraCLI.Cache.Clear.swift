import ArgumentParser
import SystemIO

extension AuraCLI.Cache {
    struct Clear {}
}
extension AuraCLI.Cache.Clear: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "clear",
            abstract: "Deletes every baked atmosphere in the cache"
        )
    }

    func run() throws {
        guard
        let directory: FilePath.Directory = AtmosphereCache.location else {
            print("The atmosphere cache is off, so there is nothing to clear.")
            return
        }
        try directory.remove()
        print("Cleared the atmosphere cache in '\(directory)'.")
    }
}
