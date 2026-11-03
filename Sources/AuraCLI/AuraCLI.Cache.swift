import ArgumentParser

extension AuraCLI {
    /// Inspects or clears the cache of baked atmospheres that `aura pack` keeps.
    struct Cache {}
}
extension AuraCLI.Cache: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "cache",
            abstract: """
            Inspects or clears the cache of baked atmospheres that 'aura pack' keeps, which \
            the environment variable AURA_CACHE can move, or turn off
            """,
            subcommands: [
                Path.self,
                Clear.self,
            ]
        )
    }
}
