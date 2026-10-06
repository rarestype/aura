import Aura
import Ion
import IonText
import SystemIO
public import SystemPackage

extension AtmosphereConfig {
    public static func load(from path: FilePath) throws -> AtmosphereConfig {
        let fileBytes: [UInt8] = try path.read([UInt8].self)

        // 1. Binary Ion (magic header: 0xE0 0x01 0x00 0xEA)
        if fileBytes.count >= 4 &&
            fileBytes[
                0
            ] == 0xe0 && fileBytes[1] == 0x01 && fileBytes[2] == 0x00 && fileBytes[3] == 0xea {
            let ion: Ion = .init(bytes: fileBytes[...])
            return try ion.decode(atomic: AtmosphereConfig.self)
        }

        // 2. Ion text
        let text: String = .init(decoding: fileBytes, as: UTF8.self)
        guard !text.isEmpty else {
            throw AtmosphereError.invalidConfigFile(
                "File is empty or not valid UTF-8 text: ‘\(path)’"
            )
        }

        return try parse(ion: text)
    }

    public static func parse(ion text: String) throws -> AtmosphereConfig {
        let ion: Ion = try .parse(atomic: text)
        return try ion.decode(atomic: AtmosphereConfig.self)
    }
}
