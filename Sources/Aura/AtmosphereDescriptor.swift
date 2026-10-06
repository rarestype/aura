public import Ion

public struct AtmosphereDescriptor: Sendable, Equatable {
    public var parameters: AtmosphereParameters
    public var tables: Tables

    init(
        parameters: AtmosphereParameters,
        tables: Tables
    ) {
        self.parameters = parameters
        self.tables = tables
    }
}

extension AtmosphereDescriptor {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case parameters
        case tables
    }
}

extension AtmosphereDescriptor: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.parameters] = self.parameters
        ion[.tables] = self.tables
    }
}

extension AtmosphereDescriptor: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            parameters: try ion[.parameters].decode(),
            tables: try ion[.tables].decode()
        )
    }
}
