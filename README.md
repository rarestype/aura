<div align="center">

🪐 &nbsp; **aura** &nbsp; 🪐

a swift library and command-line tool for precomputing multi-spectral atmospheric scattering tables

[documentation and api reference](https://swiftinit.org/docs/aura)

</div>


## Requirements

The aura library requires Swift 6.2 or later.

<!-- DO NOT EDIT BELOW! AUTOSYNC CONTENT [STATUS TABLE] -->
| Platform | Status |
| -------- | ------ |
<!-- DO NOT EDIT ABOVE! AUTOSYNC CONTENT [STATUS TABLE] -->

[Check deployment minimums](https://swiftinit.org/docs/aura#ss:platform-requirements)


## Features

Aura implements Eric Bruneton’s multiple atmospheric scattering model, generating precomputed lookup tables for:

- Optical transmittance
- Single and multiple Rayleigh and Mie scattering
- Ground and sky irradiance
- Atmospheric parameter uniforms for WebGL and shader pipelines

It supports:

- **Parameterized planetary atmospheres**: Configure arbitrary planets (such as Earth, Venus, Mars, and Titan) using Ion (`.ion`) configuration files.
- **Binary table packaging**: Directly emits IEEE-754 little-endian single-precision Float32 buffers packaged into compressed `.aura` archives, optimized for GPU texture uploads (`Float32Array` in WebGL / Three.js).
- **Ion configuration support**: Reads native binary Ion (`IonABI`) as well as human-readable Ion text files with comments, unquoted keys, and floating-point literals.

## Command-line usage

### Bake an atmosphere using an Ion configuration file

```bash
aura path/to/atmosphere.ion --detail 3 --output Public/Earth/Atmosphere
```

Or bake multiple planetary atmospheres into a single archive:

```bash
aura path/to/earth.ion path/to/mars.ion \
    --detail 3 \
    --output Public/Atmospheres/atmospheres.aura
```

### Options

- `<configs>...`: Paths to one or more Ion (`.ion`) atmospheric configuration files.
- `-d, --detail <level>`: Level of detail (1 to 5, default 3). Higher detail increases table resolution.
- `-o, --output <path>`: Output file path (e.g. `atmosphere.aura` or `atmospheres.aura`) or directory to write the archive to.

## Configuration format

Atmospheric configurations can be defined in Ion (`.ion`) files:

```ion
{
    // Atmosphere configuration for Earth
    name: "Earth",

    // Planetary geometry (meters and radians)
    radius_bottom: 6360000.0e0,
    radius_top: 6420000.0e0,
    sun_angular_radius: 0.004675e0,
    max_sun_zenith_angle: 102.0e0,

    // Rayleigh molecular scattering
    rayleigh_scale_height: 8000.0e0,
    rayleigh_scattering: [
        5.8023393817123834e-06,
        1.3557762447920223e-05,
        3.3100005976367735e-05
    ],

    // Mie aerosol scattering
    mie_scale_height: 1200.0e0,
    mie_scattering: [3.996e-06, 3.996e-06, 3.996e-06],
    mie_extinction: [4.44e-06, 4.44e-06, 4.44e-06],
    mie_albedo: 0.9e0,
    mie_g: 0.8e0,

    // Optional absorption / ozone layer (tent profile)
    ozone_extinction: [7.206534e-07, 1.7710017e-06, 6.5216177e-08],
    ozone_altitude: 25000.0e0,
    ozone_thickness: 15000.0e0,

    // Illumination and surface reflectance
    solar_irradiance: [1.49265e0, 1.850945e0, 1.7622550000000001e0],
    ground_albedo: [0.1e0, 0.1e0, 0.1e0]
}
```
