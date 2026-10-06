public import Ion

extension AtmosphereDescriptor {
    public struct Tables: Sendable, Equatable {
        public var transmittance: TableDescriptor
        public var scattering: TableDescriptor
        public var irradiance: TableDescriptor

        public init(
            transmittance: TableDescriptor,
            scattering: TableDescriptor,
            irradiance: TableDescriptor
        ) {
            self.transmittance = transmittance
            self.scattering = scattering
            self.irradiance = irradiance
        }

        public subscript(name: String) -> TableDescriptor? {
            switch name {
            case "transmittance": self.transmittance
            case "scattering": self.scattering
            case "irradiance": self.irradiance
            default: nil
            }
        }
    }
}

extension AtmosphereDescriptor.Tables {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case transmittance
        case scattering
        case irradiance
    }
}

extension AtmosphereDescriptor.Tables: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.transmittance] = self.transmittance
        ion[.scattering] = self.scattering
        ion[.irradiance] = self.irradiance
    }
}

extension AtmosphereDescriptor.Tables: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            transmittance: try ion[.transmittance].decode(),
            scattering: try ion[.scattering].decode(),
            irradiance: try ion[.irradiance].decode()
        )
    }
}
