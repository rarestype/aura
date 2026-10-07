import Ion
import IonText
import SystemIO

extension IonDecodable {
    static func load(from path: FilePath) throws -> Self {
        let ion: Ion

        let bytes: [UInt8] = try path.read([UInt8].self)
        if  bytes.starts(with: [0xE0, 0x01, 0x00, 0xEA]) {
            // binary
            ion = .init(bytes: bytes[...])
        } else {
            // text
            ion = try .parse(atomic: String.init(decoding: bytes, as: UTF8.self))
        }

        return try ion.decode(atomic: Self.self)
    }
}
