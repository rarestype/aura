import ArgumentParser
import Aura

@main struct AuraCLI: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "aura",
            abstract: "Aura 2.0 planetary appearance packaging toolkit.",
            subcommands: [
                AtmosphereCommand.self,
                PackCommand.self
            ]
        )
    }
}
