public import Ion

extension AtmosphereArchive.PlanetEntry {
    public struct Tables: Sendable, Equatable {
        public var transmittance: AtmosphereArchive.TableDescriptor
        public var scattering: AtmosphereArchive.TableDescriptor
        public var irradiance: AtmosphereArchive.TableDescriptor

        public init(
            transmittance: AtmosphereArchive.TableDescriptor,
            scattering: AtmosphereArchive.TableDescriptor,
            irradiance: AtmosphereArchive.TableDescriptor
        ) {
            self.transmittance = transmittance
            self.scattering = scattering
            self.irradiance = irradiance
        }

        public subscript(name: String) -> AtmosphereArchive.TableDescriptor? {
            switch name {
            case "transmittance": self.transmittance
            case "scattering": self.scattering
            case "irradiance": self.irradiance
            default: nil
            }
        }
    }
}

extension AtmosphereArchive.PlanetEntry.Tables {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case transmittance
        case scattering
        case irradiance
    }
}

extension AtmosphereArchive.PlanetEntry.Tables: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.transmittance] = self.transmittance
        ion[.scattering] = self.scattering
        ion[.irradiance] = self.irradiance
    }
}

extension AtmosphereArchive.PlanetEntry.Tables: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            transmittance: try ion[.transmittance].decode(),
            scattering: try ion[.scattering].decode(),
            irradiance: try ion[.irradiance].decode()
        )
    }
}
