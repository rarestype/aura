import ArgumentParser
import Aura
import SystemIO
import SystemPackage

extension AuraCLI {
    struct AtmosphereCommand: AsyncParsableCommand {
        static var configuration: CommandConfiguration {
            .init(
                commandName: "atmosphere",
                abstract: """
                Numerically solves atmospheric scattering radiative transfer equations and outputs .atmo intermediate files.
                """
            )
        }

        @Argument(
            help: "Paths to one or more atmospheric (.ion) configuration files."
        ) var configs: [String]

        @Option(
            name: [.customLong("detail"), .customShort("d")],
            help: """
            The level of detail for precomputed tables (1 to 5). Higher detail increases table resolution.
            """
        ) var detail: Int = 3

        @Option(
            name: [.customLong("threads"), .customShort("j")],
            help: "Number of threads to use for precomputation."
        ) var threads: Int = 4

        @Option(
            name: [.customLong("output"), .customShort("o")],
            help: "Destination .atmo file path or directory (defaults to .build/atmospheres/)."
        ) var output: String?

        mutating func run() async throws {
            guard !self.configs.isEmpty else {
                print("Error: No configuration files specified.")
                throw ExitCode.failure
            }

            if self.configs.count > 1 {
                if let output: String = self.output, output.hasSuffix(".atmo") {
                    print(
                        """
                        Error: Output must be a directory when multiple atmosphere configs are provided.
                        """
                    )
                    throw ExitCode.failure
                }
            }

            var atmosphereConfigs: [AtmosphereConfig] = []
            atmosphereConfigs.reserveCapacity(self.configs.count)
            for configPathString: String in self.configs {
                let configPath: FilePath = .init(configPathString)
                let config: AtmosphereConfig = try AtmosphereConfig.load(from: configPath)
                atmosphereConfigs.append(config)
            }

            for config: AtmosphereConfig in atmosphereConfigs {
                let outPath: FilePath
                if let output: String = self.output {
                    if self.configs.count == 1 && output.hasSuffix(".atmo") {
                        outPath = .init(output)
                    } else {
                        let dirPath: FilePath = .init(output)
                        outPath = dirPath.appending("\(config.name).atmo")
                    }
                } else {
                    let dirPath: FilePath = .init(".build/atmospheres")
                    outPath = dirPath.appending("\(config.name).atmo")
                }

                let parent: FilePath = outPath.removingLastComponent()
                if !parent.isEmpty {
                    try FilePath.Directory.init(path: parent).create()
                }

                print(
                    """
                    Baking atmospheric intermediate for '\(config.name)' (detail: \(
                        self.detail
                    )) to '\(
                        outPath
                    )'...
                    """
                )
                let archive: AtmosphereArchive = try await .bake(
                    config: config,
                    workers: self.threads,
                    detail: self.detail
                )
                try archive.write(to: outPath)
                print("Successfully wrote '\(outPath)'!")
            }
        }
    }
}
