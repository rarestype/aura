import Ion

public struct AtmosphereParameters: Sendable {
    public var radius_bottom: Double
    public var radius_top: Double
    public var radius_sun: Double
    public var mu_s_min: Double
    var rayleigh_scattering: Vector3<Double>
    var mie_scattering: Vector3<Double>
    public var mie_g: Double
    var resolution_transmittance: Vector2<Int>
    public var resolution_scattering4_R: Int
    public var resolution_scattering4_M: Int
    public var resolution_scattering4_MS: Int
    public var resolution_scattering4_N: Int
    var resolution_irradiance: Vector2<Int>
    var irradiance: Vector3<Double>

    init(
        radius_bottom: Double,
        radius_top: Double,
        radius_sun: Double,
        mu_s_min: Double,
        rayleigh_scattering: Vector3<Double>,
        mie_scattering: Vector3<Double>,
        mie_g: Double,
        resolution_transmittance: Vector2<Int>,
        resolution_scattering4_R: Int,
        resolution_scattering4_M: Int,
        resolution_scattering4_MS: Int,
        resolution_scattering4_N: Int,
        resolution_irradiance: Vector2<Int>,
        irradiance: Vector3<Double>
    ) {
        self.radius_bottom = radius_bottom
        self.radius_top = radius_top
        self.radius_sun = radius_sun
        self.mu_s_min = mu_s_min
        self.rayleigh_scattering = rayleigh_scattering
        self.mie_scattering = mie_scattering
        self.mie_g = mie_g
        self.resolution_transmittance = resolution_transmittance
        self.resolution_scattering4_R = resolution_scattering4_R
        self.resolution_scattering4_M = resolution_scattering4_M
        self.resolution_scattering4_MS = resolution_scattering4_MS
        self.resolution_scattering4_N = resolution_scattering4_N
        self.resolution_irradiance = resolution_irradiance
        self.irradiance = irradiance
    }
}

extension AtmosphereParameters {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case radius_bottom
        case radius_top
        case radius_sun
        case mu_s_min
        case rayleigh_scattering
        case mie_scattering
        case mie_g
        case resolution_transmittance
        case resolution_scattering4_R
        case resolution_scattering4_M
        case resolution_scattering4_MS
        case resolution_scattering4_N
        case resolution_irradiance
        case irradiance
    }
}

extension AtmosphereParameters: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.radius_bottom] = self.radius_bottom
        ion[.radius_top] = self.radius_top
        ion[.radius_sun] = self.radius_sun
        ion[.mu_s_min] = self.mu_s_min
        ion[.rayleigh_scattering] = self.rayleigh_scattering
        ion[.mie_scattering] = self.mie_scattering
        ion[.mie_g] = self.mie_g
        ion[.resolution_transmittance] = self.resolution_transmittance
        ion[.resolution_scattering4_R] = self.resolution_scattering4_R
        ion[.resolution_scattering4_M] = self.resolution_scattering4_M
        ion[.resolution_scattering4_MS] = self.resolution_scattering4_MS
        ion[.resolution_scattering4_N] = self.resolution_scattering4_N
        ion[.resolution_irradiance] = self.resolution_irradiance
        ion[.irradiance] = self.irradiance
    }
}

extension AtmosphereParameters: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            radius_bottom: try ion[.radius_bottom].decode(),
            radius_top: try ion[.radius_top].decode(),
            radius_sun: try ion[.radius_sun].decode(),
            mu_s_min: try ion[.mu_s_min].decode(),
            rayleigh_scattering: try ion[.rayleigh_scattering].decode(),
            mie_scattering: try ion[.mie_scattering].decode(),
            mie_g: try ion[.mie_g].decode(),
            resolution_transmittance: try ion[.resolution_transmittance].decode(),
            resolution_scattering4_R: try ion[.resolution_scattering4_R].decode(),
            resolution_scattering4_M: try ion[.resolution_scattering4_M].decode(),
            resolution_scattering4_MS: try ion[.resolution_scattering4_MS].decode(),
            resolution_scattering4_N: try ion[.resolution_scattering4_N].decode(),
            resolution_irradiance: try ion[.resolution_irradiance].decode(),
            irradiance: try ion[.irradiance].decode()
        )
    }
}
