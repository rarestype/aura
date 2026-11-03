import ArgumentParser
import Aura

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

@main struct AuraCLI: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "aura",
            abstract: "Aura 2.0 planetary appearance packaging toolkit",
            subcommands: [
                Bake.self,
                Pack.self,
                Cache.self,
            ]
        )
    }
}
extension AuraCLI {
    /// The number of processors available, which is how many threads a bake uses by default,
    /// since a bake produces the same output with any number of threads.
    static var processors: Int {
        max(1, Int.init(sysconf(Int32.init(_SC_NPROCESSORS_ONLN))))
    }
}
