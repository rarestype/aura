public import Ion
import IonText
import SystemIO
public import SystemPackage

public struct PackagingManifest: Sendable {
    public static var currentVersion: UInt32 { 1 }

    public var version: UInt32
    public var output: String
    public var planets: [PlanetEntry]

    public init(
        version: UInt32 = Self.currentVersion,
        output: String,
        planets: [PlanetEntry]
    ) {
        self.version = version
        self.output = output
        self.planets = planets
    }
}

extension PackagingManifest {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case version
        case output
        case planets
    }
}

extension PackagingManifest: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.version] = self.version
        ion[.output] = self.output
        ion[.planets] = self.planets
    }
}

extension PackagingManifest: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            version: try ion[.version].decode(),
            output: try ion[.output].decode(),
            planets: try ion[.planets].decode()
        )
    }
}

extension PackagingManifest {
    public static func load(from path: FilePath) throws -> PackagingManifest {
        let fileBytes: [UInt8] = try path.read([UInt8].self)

        // 1. Binary Ion (magic header: 0xE0 0x01 0x00 0xEA)
        if fileBytes.count >= 4 &&
            fileBytes[
                0
            ] == 0xe0 && fileBytes[1] == 0x01 && fileBytes[2] == 0x00 && fileBytes[3] == 0xea {
            let ion: Ion = .init(bytes: fileBytes[...])
            return try ion.decode(atomic: PackagingManifest.self)
        }

        // 2. Ion text
        let text: String = .init(decoding: fileBytes, as: UTF8.self)
        guard !text.isEmpty else {
            throw AtmosphereError.invalidConfigFile(
                "Manifest file is empty or not valid UTF-8 text: ‘\(path)’"
            )
        }

        let ion: Ion = try .parse(atomic: text)
        return try ion.decode(atomic: PackagingManifest.self)
    }
}
