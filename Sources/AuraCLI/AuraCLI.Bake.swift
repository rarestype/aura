import ArgumentParser
import Aura
import SystemIO
import System_ArgumentParser
import SystemPackage

extension AuraCLI {
    struct Bake {
        @Argument(
            help: "Paths to one or more atmospheric (.ion) configuration files"
        ) var configurations: [FilePath]

        @Option(
            name: [.customLong("detail"), .customShort("d")],
            help: """
            The level of detail for precomputed tables (1 to 5). \
            Higher detail increases table resolution
            """
        ) var detail: Int = 3

        @Option(
            name: [.customLong("threads"), .customShort("j")],
            help: "Number of threads to use for precomputation."
        ) var threads: Int = 4

        @Option(
            name: [.customLong("output"), .customShort("o")],
            help: "Destination .atmo file path or directory"
        ) var output: FilePath = ".build/atmospheres"
    }
}
extension AuraCLI.Bake: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "bake",
            abstract: """
            Numerically solves atmospheric scattering radiative transfer equations \
            and outputs .atmo intermediate files
            """
        )
    }

    mutating func run() async throws {
        if  self.configurations.isEmpty {
            throw ValidationError.init("No configuration files provided")
        }

        guard 1 ... 5 ~= self.detail else {
            throw ValidationError.init("Detail must be between 1 and 5")
        }

        let single: FilePath?
        if  case "atmo"? = self.output.extension {
            guard self.configurations.count == 1 else {
                throw ValidationError.init(
                    """
                    When output is an .atmo file, only one \
                    configuration file may be provided
                    """
                )
            }

            try self.output.parent?.create()
            single = self.output

        } else {
            try self.output.directory.create()
            single = nil
        }

        let configurations: [AtmosphereConfiguration] = try self.configurations.map {
            try AtmosphereConfiguration.load(from: $0)
        }

        for body: AtmosphereConfiguration in configurations {
            let output: FilePath = single ?? self.output.directory / "\(body.name).atmo"

            print(
                """
                Baking atmospheric intermediate for '\(body.name)' \
                (detail: \(self.detail)) to '\(output)'...
                """
            )

            let archive: AtmosphereArchive = await .bake(
                body,
                detail: self.detail,
                workers: self.threads,
            )
            try archive.write(to: output)

            print("Successfully wrote '\(output)'!")
        }
    }
}
