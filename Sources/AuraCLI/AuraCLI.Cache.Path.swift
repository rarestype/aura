import ArgumentParser
import SystemIO

extension AuraCLI.Cache {
    struct Path {}
}
extension AuraCLI.Cache.Path: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "path",
            abstract: "Prints the directory of the atmosphere cache, or 'off'"
        )
    }

    func run() {
        if  let directory: FilePath.Directory = AtmosphereCache.location {
            print(directory)
        } else {
            print("off")
        }
    }
}
