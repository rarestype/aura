public import Ion

public struct AtmosphereConfig: Sendable {
    public var name: String

    // Planetary geometry (meters and degrees)
    public var radius_bottom: Double
    public var radius_top: Double
    public var sun_angular_radius: Double
    public var max_sun_zenith_angle: Double

    // Rayleigh scattering (molecular gas)
    public var rayleigh_scale_height: Double
    public var rayleigh_scattering: [Double]

    // Mie scattering (aerosols / haze)
    public var mie_scale_height: Double
    public var mie_scattering: [Double]
    public var mie_extinction: [Double]?
    public var mie_albedo: Double?
    public var mie_g: Double

    // Ozone absorption (tent profile)
    public var ozone_extinction: [Double]?
    public var ozone_altitude: Double?
    public var ozone_thickness: Double?

    // Illumination
    public var solar_irradiance: [Double]
    public var ground_albedo: [Double]

    public init(
        name: String,
        radius_bottom: Double,
        radius_top: Double,
        sun_angular_radius: Double,
        max_sun_zenith_angle: Double,
        rayleigh_scale_height: Double,
        rayleigh_scattering: [Double],
        mie_scale_height: Double,
        mie_scattering: [Double],
        mie_extinction: [Double]? = nil,
        mie_albedo: Double? = nil,
        mie_g: Double,
        ozone_extinction: [Double]? = nil,
        ozone_altitude: Double? = nil,
        ozone_thickness: Double? = nil,
        solar_irradiance: [Double],
        ground_albedo: [Double]
    ) {
        self.name = name
        self.radius_bottom = radius_bottom
        self.radius_top = radius_top
        self.sun_angular_radius = sun_angular_radius
        self.max_sun_zenith_angle = max_sun_zenith_angle
        self.rayleigh_scale_height = rayleigh_scale_height
        self.rayleigh_scattering = rayleigh_scattering
        self.mie_scale_height = mie_scale_height
        self.mie_scattering = mie_scattering
        self.mie_extinction = mie_extinction
        self.mie_albedo = mie_albedo
        self.mie_g = mie_g
        self.ozone_extinction = ozone_extinction
        self.ozone_altitude = ozone_altitude
        self.ozone_thickness = ozone_thickness
        self.solar_irradiance = solar_irradiance
        self.ground_albedo = ground_albedo
    }
}

extension AtmosphereConfig {
    @frozen public enum CodingKey: String, IonSymbolizable {
        case name
        case radius_bottom
        case radius_top
        case sun_angular_radius
        case max_sun_zenith_angle
        case rayleigh_scale_height
        case rayleigh_scattering
        case mie_scale_height
        case mie_scattering
        case mie_extinction
        case mie_albedo
        case mie_g
        case ozone_extinction
        case ozone_altitude
        case ozone_thickness
        case solar_irradiance
        case ground_albedo
    }
}

extension AtmosphereConfig: IonEncodableStruct {
    public func encode(to ion: inout Ion.StructEncoder<CodingKey>) {
        ion[.name] = self.name
        ion[.radius_bottom] = self.radius_bottom
        ion[.radius_top] = self.radius_top
        ion[.sun_angular_radius] = self.sun_angular_radius
        ion[.max_sun_zenith_angle] = self.max_sun_zenith_angle
        ion[.rayleigh_scale_height] = self.rayleigh_scale_height
        ion[.rayleigh_scattering] = self.rayleigh_scattering
        ion[.mie_scale_height] = self.mie_scale_height
        ion[.mie_scattering] = self.mie_scattering
        ion[.mie_extinction] = self.mie_extinction
        ion[.mie_albedo] = self.mie_albedo
        ion[.mie_g] = self.mie_g
        ion[.ozone_extinction] = self.ozone_extinction
        ion[.ozone_altitude] = self.ozone_altitude
        ion[.ozone_thickness] = self.ozone_thickness
        ion[.solar_irradiance] = self.solar_irradiance
        ion[.ground_albedo] = self.ground_albedo
    }
}

extension AtmosphereConfig: IonDecodableStruct {
    public init(ion: borrowing Ion.StructDecoder<CodingKey>) throws {
        self.init(
            name: try ion[.name].decode(),
            radius_bottom: try ion[.radius_bottom].decode(),
            radius_top: try ion[.radius_top].decode(),
            sun_angular_radius: try ion[.sun_angular_radius].decode(),
            max_sun_zenith_angle: try ion[.max_sun_zenith_angle].decode(),
            rayleigh_scale_height: try ion[.rayleigh_scale_height].decode(),
            rayleigh_scattering: try ion[.rayleigh_scattering].decode(),
            mie_scale_height: try ion[.mie_scale_height].decode(),
            mie_scattering: try ion[.mie_scattering].decode(),
            mie_extinction: try ion[.mie_extinction]?.decode(),
            mie_albedo: try ion[.mie_albedo]?.decode(),
            mie_g: try ion[.mie_g].decode(),
            ozone_extinction: try ion[.ozone_extinction]?.decode(),
            ozone_altitude: try ion[.ozone_altitude]?.decode(),
            ozone_thickness: try ion[.ozone_thickness]?.decode(),
            solar_irradiance: try ion[.solar_irradiance].decode(),
            ground_albedo: try ion[.ground_albedo].decode()
        )
    }
}
