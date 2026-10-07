public import Ion

public struct Atmosphere: Sendable {
    public var transmittance: Table
    public var scattering: Table
    public var irradiance: Table
    public var parameters: AtmosphereParameters

    init(
        transmittance: Table,
        scattering: Table,
        irradiance: Table,
        parameters: AtmosphereParameters,
    ) {
        self.transmittance = transmittance
        self.scattering = scattering
        self.irradiance = irradiance
        self.parameters = parameters
    }
}

extension Atmosphere {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case transmittance
        case scattering
        case irradiance
        case parameters
    }
}

extension Atmosphere: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.transmittance] = self.transmittance
        ion[.scattering] = self.scattering
        ion[.irradiance] = self.irradiance
        ion[.parameters] = self.parameters
    }
}

extension Atmosphere: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            transmittance: try ion[.transmittance].decode(),
            scattering: try ion[.scattering].decode(),
            irradiance: try ion[.irradiance].decode(),
            parameters: try ion[.parameters].decode(),
        )
    }
}
