public import Aura

extension AtmosphereConfiguration {
    public static var earth: Self {
        .init(
            name: "Earth",
            radius_bottom: 6360000.0,
            radius_top: 6420000.0,
            sun_angular_radius: 0.004675,
            max_sun_zenith_angle: 102.0,
            rayleigh_scale_height: 8000.0,
            rayleigh_scattering: [
                5.8023393817123834e-06,
                1.3557762447920223e-05,
                3.3100005976367735e-05
            ],
            mie_scale_height: 1200.0,
            mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
            mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
            mie_albedo: 0.9,
            mie_g: 0.8,
            ozone_extinction: [7.206534e-07, 1.7710017e-06, 6.5216177e-08],
            ozone_altitude: 25000.0,
            ozone_thickness: 15000.0,
            solar_irradiance: [1.49265, 1.850945, 1.7622550000000001],
            ground_albedo: [0.1, 0.1, 0.1]
        )
    }

    public static var mars: Self {
        .init(
            name: "Mars",
            radius_bottom: 3389500.0,
            radius_top: 3450000.0,
            sun_angular_radius: 0.003067,
            max_sun_zenith_angle: 100.0,
            rayleigh_scale_height: 11100.0,
            rayleigh_scattering: [1.9e-07, 4.5e-07, 1.1e-06],
            mie_scale_height: 2000.0,
            mie_scattering: [4.0e-06, 3.2e-06, 2.0e-06],
            mie_extinction: [4.5e-06, 3.8e-06, 2.8e-06],
            mie_albedo: 0.85,
            mie_g: 0.7,
            solar_irradiance: [0.642, 0.796, 0.758],
            ground_albedo: [0.25, 0.15, 0.1]
        )
    }
}
