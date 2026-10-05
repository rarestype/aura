import ArgumentParser
import Aura
import SystemPackage

@main struct AuraCLI: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "aura",
            abstract: """
            Precomputes atmospheric scattering lookup tables for planetary rendering.
            """
        )
    }

    @Argument(
        help: "Paths to one or more Ion (.ion) atmospheric configuration files."
    ) var configs: [String]

    @Option(
        name: .shortAndLong,
        help: """
        The level of detail for precomputed tables (1 to 5). \
        Higher detail increases table resolution.
        """
    ) var detail: Int = 3

    @Option(
        name: .shortAndLong,
        help: """
        Output file path (e.g. ‘atmosphere.aura’ or ‘atmospheres.aura’) \
        or directory to write archive to.
        """
    ) var output: String?

    func run() throws {
        guard !self.configs.isEmpty else {
            print("Error: No configuration files specified.")
            throw ExitCode.failure
        }

        var atmosphereConfigs: [AtmosphereConfig] = []
        atmosphereConfigs.reserveCapacity(self.configs.count)

        for configPathString: String in self.configs {
            let configPath: FilePath = .init(configPathString)
            let config: AtmosphereConfig = try AtmosphereConfig.load(from: configPath)
            atmosphereConfigs.append(config)
        }

        let outString: String
        if let output: String = self.output {
            if output.hasSuffix(".aura") {
                outString = output
            } else {
                let filename: String = atmosphereConfigs.count > 1 ? "atmospheres.aura" : """
                atmosphere.aura
                """
                outString = output.hasSuffix(
                    "/"
                ) ? "\(output)\(filename)" : "\(output)/\(filename)"
            }
        } else {
            if atmosphereConfigs.count == 1 {
                outString = "Public/\(atmosphereConfigs[0].name)/Atmosphere/atmosphere.aura"
            } else {
                outString = "Public/Atmospheres/atmospheres.aura"
            }
        }

        let outPath: FilePath = .init(outString)
        let parent: FilePath = outPath.removingLastComponent()
        if !parent.isEmpty {
            try FilePath.Directory(path: parent).create()
        }

        let names: String = atmosphereConfigs.map(\.name).joined(separator: ", ")
        print(
            """
            Baking atmosphere archive for [\(names)] (detail: \(self.detail)) to '\(
                outString
            )'...
            """
        )
        let archive: AtmosphereArchive = try .bake(
            configs: atmosphereConfigs,
            detail: self.detail
        )
        try archive.write(to: outPath)
        print("Successfully baked atmosphere archive to '\(outString)'!")
    }
}
