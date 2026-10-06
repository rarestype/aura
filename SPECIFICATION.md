# Planetary appearance packaging specification

This specification defines the architecture, file formats, CLI interface, and schemas for Aura 2.0 planetary appearance assets.

---

## 1. Overview and objectives

An `.aura` file is an uncompressed Amazon Ion binary archive (`IonABI`) that provides all visual and physical parameters required by the WebGL renderer to display one or more celestial bodies.

### Primary goals

1. **Atomic single-request loading:**  
   Collapses up to 13 separate HTTP requests per body (6 albedo faces + 6 relief normal faces + 1 atmosphere table file) into a **single network fetch**.
2. **Multi-body bundling:**  
   Supports packing multiple coupled celestial bodies into a single archive (for example, packaging Earth and the Moon together, or Jupiter and its Galilean satellites). When the client navigates to a planetary system, visual assets for both the primary body and its major satellites are retrieved in a single request.
3. **Format standardization:**  
   Standardizes exclusively on **WebP** for all surface texture faces (`px.webp`, `nx.webp`, `py.webp`, `ny.webp`, `pz.webp`, `nz.webp`).
4. **Targeted compression without whole-archive Gzip:**  
   WebP images are already entropy-compressed; running Gzip over them yields essentially 0% compression while wasting CPU cycles on both build machines and client devices. Instead, the `.aura` archive itself is an **uncompressed binary Ion structure**. Compression is applied **only to the atmosphere tables** (which contain raw `Float32` arrays that compress by 80–90%).
5. **Direct JavaScript / WebGL decoding without WebAssembly bottleneck:**  
   JavaScript/TypeScript directly parses the Ion archive using `ion-js` and feeds the WebP byte blobs straight into browser-native, off-thread `createImageBitmap(blob)`. Texture bytes never touch WebAssembly memory. WebAssembly is only invoked for specialized mathematical reconstruction (such as atmospheric table deshuffling).
6. **Decoupled build pipeline:**  
   Separates heavy numerical physics computations (atmospheric scattering simulation) from asset packaging (texture bundling) via a **build intermediate (`.atmo`)**, enabling visual texture iteration times under 50 milliseconds.

---

## 2. Units and coordinate systems

The system strictly delineates between astronomical simulation units and atmospheric radiative transfer units:

| Domain | Parameter | Unit | Notes |
| :--- | :--- | :--- | :--- |
| **Atmosphere subsystem** | `radius_bottom`, `radius_top` | **Meters** ($\text{m}$) | Matches Bruneton (2017) radiative transfer equations (e.g. `6360000.0e0` for Earth). |
| | Scale heights (`rayleigh_scale_height`, `mie_scale_height`) | **Meters** ($\text{m}$) | e.g. `8000.0e0` for Earth Rayleigh, `1200.0e0` for Mie. |
| | Scattering coefficients (`rayleigh_scattering`, `mie_scattering`) | $\text{m}^{-1}$ | Volumetric scattering coefficients. |
| | Solar irradiance (`sun_irradiance`) | $\text{W} / \text{m}^2$ | Solar spectral irradiance at top of atmosphere. |
| **Planetary geometry** | Body radius (`radius`) | **Kilometers** ($\text{km}$) | Standard astronomical catalog convention (e.g. `6371.0e0` for Earth, `1737.4e0` for the Moon). |
| | Axial tilt (`tilt`) | **Radians** | Angle between rotation axis and orbital plane normal. |
| | Flattening (`flattening`) | **Dimensionless** | Geometric oblateness: $(a - b) / a$. |
| | Relief elevation scale (`relief_scale`) | **Dimensionless** | Normal map height multiplier (default: `1.0`). |

### Coordinate conversions in the client

In the WebGL renderer (`ParametricSpheroid.ts`):
1. Astronomical radius in kilometers is converted to scene Astronomical Units:
   $$\text{equatorialRadius} = \frac{\text{radius}_{\text{km}}}{149597870.7}$$
2. The outer radius of the atmosphere rendering envelope is computed as a dimensionless ratio against the base radius:
   $$\text{atmosphereTopRadius} = \text{equatorialRadius} \times \left(\frac{\text{radius\_top}}{\text{radius\_bottom}}\right)$$
   Because $\text{radius\_top}$ and $\text{radius\_bottom}$ are both in meters, their units cancel cleanly.

---

## 3. Decoupled build pipeline

Atmospheric scattering simulation requires solving Bruneton’s radiative transfer integral equations, which is compute-intensive. Conversely, texture packaging is purely I/O and Ion serialization.

To preserve sub-second iteration during art and shader development, the pipeline introduces a **build intermediate** for atmospheric scattering tables.

```
[World/Atmospheres/<Planet>.ion]
               │
               ▼  (aura atmosphere: slow numerical solve, run on config changes)
[.build/atmospheres/<Planet>.atmo] (intermediate binary table cache)
               │
               │  ◄── [Public/<Planet>/*.webp] (6 albedo faces)
               │  ◄── [Public/<Planet>/Relief/*.webp] (6 optional relief faces)
               ▼  (aura pack: fast I/O assembly, <50 ms)
[Public/<Planet>.aura] (final web-ready archive)
```

* **When texture art changes:** The developer re-runs `aura pack`, which bundles the updated WebP images with the cached `.atmo` intermediate in tens of milliseconds.
* **When atmosphere parameters change:** The developer re-runs `aura atmosphere` to regenerate the `.atmo` intermediate.
* **Airless bodies:** Bodies without atmospheres (such as the Moon or Mercury) bypass the atmospheric solver entirely and only run `aura pack`.

---

## 4. Intermediate format: `.atmo`

The `.atmo` intermediate file is an **uncompressed binary Amazon Ion structure** (`IonABI`) produced by `aura atmosphere`. It serializes an `AtmosphereArchive` file container holding an `AtmosphereDescriptor` for a single celestial body.

### `.atmo` Ion schema

```ion
$ion_1_0
{
    version: 1,
    name: "Earth",
    atmosphere: {
        parameters: {
            radius_bottom: 6360000.0e0,
            radius_top: 6420000.0e0,
            radius_sun: 696340000.0e0,
            mu_s_min: -0.2079117e0,
            rayleigh_scattering: [5.802339e-6, 1.355776e-5, 3.310001e-5],
            mie_scattering: [3.996e-6, 3.996e-6, 3.996e-6],
            mie_g: 0.8e0,
            resolution_transmittance: [256, 64],
            resolution_scattering4_R: 32,
            resolution_scattering4_M: 8,
            resolution_scattering4_MS: 128,
            resolution_scattering4_N: 32,
            resolution_irradiance: [64, 16],
            irradiance: [1.474e0, 1.697e0, 1.778e0]
        },
        tables: {
            // Individual table buffers are byte-shuffled and Deflate-compressed Float32 blobs
            transmittance: {
                width: 256,
                height: 64,
                data: {{ ...deflated Float32 blob... }}
            },
            scattering: {
                width: 256,
                height: 128,
                depth: 32,
                data: {{ ...deflated Float32 blob... }}
            },
            irradiance: {
                width: 64,
                height: 16,
                data: {{ ...deflated Float32 blob... }}
            }
        }
    }
}
```

### Table resolution parameters

The resolution fields (`resolution_transmittance`, `resolution_scattering4_R`, etc.) are retained in `parameters`:
* While `width`, `height`, and `depth` describe the allocated texture extents, the 4D scattering coordinate parametrization $(R, \mu, \mu_s, \nu)$ depends on the specific coordinate divisions $(R=32, M=8, MS=128, N=32)$.
* Retaining these explicit integers ensures the shader coordinate mapping functions remain completely self-describing regardless of detail settings.

---

## 5. Unified archive format: `.aura`

The `.aura` file is an **uncompressed binary Amazon Ion container** (`IonABI`) representing a `PlanetaryArchive`.

### `.aura` Ion schema

```ion
$ion_1_0
{
    version: 2,
    planets: [
        {
            name: "Earth",
            parameters: {
                radius: 6371.0e0,
                tilt: 0.4084e0,
                flattening: 0.00335e0,
                relief_scale: 1.0e0
            },
            surface: {
                albedo: {
                    px: {{ ...binary webp blob... }},
                    nx: {{ ...binary webp blob... }},
                    py: {{ ...binary webp blob... }},
                    ny: {{ ...binary webp blob... }},
                    pz: {{ ...binary webp blob... }},
                    nz: {{ ...binary webp blob... }}
                },
                // Optional: omitted if planet has no relief normal map
                relief: {
                    px: {{ ...binary webp blob... }},
                    nx: {{ ...binary webp blob... }},
                    py: {{ ...binary webp blob... }},
                    ny: {{ ...binary webp blob... }},
                    pz: {{ ...binary webp blob... }},
                    nz: {{ ...binary webp blob... }}
                }
            },
            // Optional: omitted for airless bodies.
            // Notice: contains an AtmosphereDescriptor (parameters + tables),
            // omitting redundant container fields (version and name).
            atmosphere: {
                parameters: {
                    radius_bottom: 6360000.0e0,
                    radius_top: 6420000.0e0,
                    radius_sun: 696340000.0e0,
                    mu_s_min: -0.2079117e0,
                    rayleigh_scattering: [5.802339e-6, 1.355776e-5, 3.310001e-5],
                    mie_scattering: [3.996e-6, 3.996e-6, 3.996e-6],
                    mie_g: 0.8e0,
                    resolution_transmittance: [256, 64],
                    resolution_scattering4_R: 32,
                    resolution_scattering4_M: 8,
                    resolution_scattering4_MS: 128,
                    resolution_scattering4_N: 32,
                    resolution_irradiance: [64, 16],
                    irradiance: [1.474e0, 1.697e0, 1.778e0]
                },
                tables: {
                    transmittance: { width: 256, height: 64, data: {{ ...deflated Float32 blob... }} },
                    scattering: { width: 256, height: 128, depth: 32, data: {{ ...deflated Float32 blob... }} },
                    irradiance: { width: 64, height: 16, data: {{ ...deflated Float32 blob... }} }
                }
            }
        },
        {
            name: "The Moon",
            parameters: {
                radius: 1737.4e0,
                tilt: 0.0269e0,
                flattening: 0.0e0,
                relief_scale: 1.5e0
            },
            surface: {
                albedo: {
                    px: {{ ...binary webp blob... }},
                    nx: {{ ...binary webp blob... }},
                    py: {{ ...binary webp blob... }},
                    ny: {{ ...binary webp blob... }},
                    pz: {{ ...binary webp blob... }},
                    nz: {{ ...binary webp blob... }}
                },
                relief: {
                    px: {{ ...binary webp blob... }},
                    nx: {{ ...binary webp blob... }},
                    py: {{ ...binary webp blob... }},
                    ny: {{ ...binary webp blob... }},
                    pz: {{ ...binary webp blob... }},
                    nz: {{ ...binary webp blob... }}
                }
            }
        }
    ]
}
```

### Parameter provenance

Where do `radius`, `tilt`, `flattening`, and `relief_scale` come from during packaging?
1. **In manifest-driven packaging (`aura pack --manifest <path>`):** Explicitly declared under each planet’s `parameters` section.
2. **In single-body packaging (`aura pack <textures>`):** Provided via optional CLI flags (`--radius`, `--tilt`, `--flattening`, `--relief-scale`).
3. **Defaults:** If omitted, `radius` defaults to `1.0`, `tilt` to `0.0`, `flattening` to `0.0`, and `relief_scale` to `1.0`. In the live game, the simulation’s `CelestialBodyState` acts as the authoritative ephemeris source for dynamic orbital orientation and position.

---

## 6. CLI interface

The `aura` CLI executable provides two dedicated subcommands:

### 6.1. `aura atmosphere`

Numerically solves atmospheric scattering radiative transfer equations and outputs `.atmo` intermediate files.

```bash
aura atmosphere <configs...> [--detail <1-5>] [--output <path>]
```

* **Arguments:**
  * `<configs...>`: Paths to one or more atmospheric `.ion` configuration files (e.g. `World/Atmospheres/Earth.ion`).
* **Options:**
  * `-d, --detail <1-5>`: Resolution detail level (default: `3`).
  * `-o, --output <path>`: Destination `.atmo` file path or directory (defaults to `.build/atmospheres/`).
* **Multi-config output rules:**
  * When multiple configuration files are passed, `--output` must be a **directory**. The tool writes `<output_dir>/<Name>.atmo` for each configuration (where `<Name>` is the `name` property declared in the `.ion` config). If a single file path (e.g. ending in `.atmo`) is provided when passing multiple configs, `aura atmosphere` fails immediately with exit code 1:
    ```
    Error: Output must be a directory when multiple atmosphere configs are provided.
    ```
  * When a single configuration file is passed, `--output` may be either a directory (producing `<output_dir>/<Name>.atmo`) or an explicit file path (e.g. `.build/atmospheres/Earth.atmo`).

### 6.2. `aura pack`

Assembles surface textures, physical parameters, and optional `.atmo` atmosphere intermediates into a `.aura` archive.

```bash
aura pack [<textures>] \
    [--manifest <path.ion>] \
    [--name <name>] \
    [--atmosphere <path.atmo>] \
    [--relief-scale <float>] \
    [--radius <km>] \
    [--tilt <radians>] \
    [--flattening <float>] \
    [--output <path.aura>]
```

#### Argument rules and mutual exclusion

To comply with `System_ArgumentParser`:
* The positional `<textures>` argument is declared as optional (`var textures: String?`).
* `--manifest` and `<textures>` are mutually exclusive:
  * If `--manifest` is provided, `<textures>` must be omitted.
  * If `--manifest` is omitted, `<textures>` is required.
  * If both or neither are provided, `aura pack` fails immediately with exit code 1.

#### Single-body mode

```bash
aura pack "Public/Earth" \
    --name "Earth" \
    --atmosphere ".build/atmospheres/Earth.atmo" \
    --output "Public/Earth.aura"
```

* `<textures>`: Directory containing `px.webp`, `nx.webp`, `py.webp`, `ny.webp`, `pz.webp`, `nz.webp`. If a `Relief/` subdirectory is present, its 6 WebP faces are packaged as the relief normal map.
* `--name <name>`: Planet name (defaults to the directory name of `<textures>`).
* `--output <path.aura>`: Destination file path (defaults to `<textures>/../<name>.aura`).

#### Multi-body mode (primary)

Multi-body packaging is specified declaratively via an Ion assembly manifest:

```bash
aura pack --manifest "World/Planetarium/earth_moon.ion"
```

#### Manifest path resolution

All relative paths declared inside `manifest.ion` (`output`, `textures`, `atmosphere`) are **resolved relative to the directory containing the manifest file**, not the current working directory. This ensures builds are reproducible and independent of where the tool is executed.

#### Assembly manifest schema (`manifest.ion`)

```ion
$ion_1_0
{
    version: 1,
    output: "../../Public/Earth-Moon.aura",
    planets: [
        {
            name: "Earth",
            textures: "../../Public/Earth",
            atmosphere: "../../.build/atmospheres/Earth.atmo",
            parameters: {
                radius: 6371.0e0,
                tilt: 0.4084e0,
                flattening: 0.00335e0,
                relief_scale: 1.0e0
            }
        },
        {
            name: "The Moon",
            textures: "../../Public/The Moon",
            parameters: {
                radius: 1737.4e0,
                tilt: 0.0269e0,
                flattening: 0.0e0,
                relief_scale: 1.5e0
            }
        }
    ]
}
```

---

## 7. Error handling and validation

`aura pack` enforces strict validation to ensure archives are never written in corrupted or incomplete states:

1. **Missing albedo face files:**  
   If any of `px.webp`, `nx.webp`, `py.webp`, `ny.webp`, `pz.webp`, `nz.webp` are missing from the `<textures>` directory, `aura pack` fails immediately with exit code 1:
   ```
   Error: Missing required albedo faces in 'Public/Earth': [py.webp, ny.webp]
   ```
2. **Partial `Relief/` directory:**  
   If a `Relief/` subdirectory exists, it must contain **all 6** faces. If fewer than 6 faces are found, `aura pack` fails immediately with exit code 1:
   ```
   Error: Incomplete relief normal map in 'Public/The Moon/Relief': missing [pz.webp]
   ```
   If the `Relief/` directory is entirely absent, relief mapping is cleanly omitted.
3. **Missing or corrupt `.atmo` file:**  
   If an atmosphere path is provided but the file does not exist or fails Ion decoding, `aura pack` fails immediately with exit code 1:
   ```
   Error: Atmosphere intermediate not found at '.build/atmospheres/Earth.atmo'
   ```
4. **Manifest validation errors:**  
   If a manifest specifies non-existent texture directories or invalid parameter types, `aura pack` aborts before writing output.

---

## 8. Swift library API (`Aura` and `AuraDecoding`)

### Domain separation: `AtmosphereDescriptor` vs `AtmosphereArchive`

To prevent schema contradictions and eliminate redundant fields when embedding atmosphere tables:
* **`AtmosphereDescriptor` (`parameters` + `tables`):**  
  The pure payload holding physical atmosphere parameters and precomputed table descriptors. This is the exact type embedded under `atmosphere` in `PlanetaryArchive.PlanetEntry`.
* **`AtmosphereArchive` (`version` + `name` + `atmosphere`):**  
  The top-level file container for `.atmo` intermediate files. It wraps `AtmosphereDescriptor` alongside the planet’s identity and schema version.

```swift
public struct AtmosphereDescriptor: Sendable, Equatable {
    public var parameters: AtmosphereParameters
    public var tables: Tables

    public struct Tables: Sendable, Equatable {
        public var transmittance: TableDescriptor
        public var scattering: TableDescriptor
        public var irradiance: TableDescriptor
    }

    public struct TableDescriptor: Sendable, Equatable {
        public var width: Int
        public var height: Int
        public var depth: Int?
        public var data: [UInt8]
    }
}

public struct AtmosphereArchive: Sendable, Equatable {
    public var version: UInt32
    public var name: String
    public var atmosphere: AtmosphereDescriptor
}
```

### Planetary archive schema

```swift
public struct PlanetaryArchive: Sendable, Equatable {
    public var version: UInt32
    public var planets: [PlanetEntry]

    public struct PlanetEntry: Sendable, Equatable {
        public var name: String
        public var parameters: SurfaceParameters
        public var surface: SurfaceDescriptor
        public var atmosphere: AtmosphereDescriptor?
    }

    public struct SurfaceParameters: Sendable, Equatable {
        public var radius: Double
        public var tilt: Double
        public var flattening: Double
        public var reliefScale: Double
    }

    public struct SurfaceDescriptor: Sendable, Equatable {
        public var albedo: CubemapFaces
        public var relief: CubemapFaces?
    }

    public struct CubemapFaces: Sendable, Equatable {
        public var px: [UInt8]
        public var nx: [UInt8]
        public var py: [UInt8]
        public var ny: [UInt8]
        public var pz: [UInt8]
        public var nz: [UInt8]
    }
}
```

### Host-side table decompression and extraction

In `AtmosphereDescriptor.Tables`, each table’s `data` contains Deflate-compressed bytes. On the host side:
1. `TableCompression.inflate(descriptor.data)` decompresses the Deflate stream.
2. `AtmosphereTableDecoder.decode(shuffled:width:height:depth:)` reverses byte plane shuffling and filtering to yield reconstructed `SIMD4<Float>` texels.

### One Type Per File convention

In accordance with the project’s [institutional Swift style guide](file:///swift/aura/AGENTS.md), each nested structure and extension must be placed in its own dedicated source file matching its qualified type name:

```
Sources/Aura/
├── AtmosphereArchive.swift
├── AtmosphereArchive.Error.swift
├── AtmosphereDescriptor.swift
├── AtmosphereDescriptor.Tables.swift
├── AtmosphereDescriptor.TableDescriptor.swift
├── AtmosphereParameters.swift
├── AtmosphereConfig.swift
├── PlanetaryArchive.swift
├── PlanetaryArchive.PlanetEntry.swift
├── PlanetaryArchive.SurfaceParameters.swift
├── PlanetaryArchive.SurfaceDescriptor.swift
├── PlanetaryArchive.CubemapFaces.swift
├── TableCompression.swift
└── ...
```

### Binary blob encoding

All binary payloads—including cubemap texture faces in `PlanetaryArchive.CubemapFaces` (`px`, `nx`, `py`, `ny`, `pz`, `nz`) and table buffers in `AtmosphereDescriptor.TableDescriptor` (`data`)—must be encoded as binary Amazon Ion blobs (`{{ ... }}`). In Swift, these byte collections must be wrapped and decoded using `Ion.BlobView<[UInt8], Ion.BlobType>` (and `Ion.BlobView<ArraySlice<UInt8>, Ion.BlobType>`) to ensure they serialize as Ion binary blobs rather than integer sequences.

### Serialization, deserialization, and test support

All structures conform to **both `IonEncodableStruct` and `IonDecodableStruct`**:

```swift
extension PlanetaryArchive {
    public func serialize() throws -> [UInt8]
    public static func deserialize(from bytes: [UInt8]) throws -> PlanetaryArchive
}

extension AtmosphereArchive {
    public func serialize() throws -> [UInt8]
    public static func deserialize(from bytes: [UInt8]) throws -> AtmosphereArchive
}
```

* **Unit and golden testing:** Round-trip deserialization (`serialize()` followed by `deserialize(from:)`) is fully supported and tested in `AuraTests` and `AuraGoldenTests` to guarantee binary compatibility and serialization fidelity.
* **Execution boundary:** `PlanetaryArchive.deserialize(from:)` is a host-side Swift utility. It is **not** called by the in-game WebAssembly engine, ensuring that large WebP byte arrays are never duplicated in the Wasm linear heap.

---

## 9. Client integration (TypeScript & WebGL)

### Architectural responsibility boundary

* **JavaScript (client thread):**
  1. Fetches the `.aura` binary using standard HTTP GET.
  2. Parses the uncompressed Ion document directly using `ion-js`.
  3. Extracts the WebP byte blobs and passes them to `createImageBitmap(blob)`.
  4. Decompresses raw atmosphere table Deflate blobs using browser-native `DecompressionStream('deflate')`.
  5. Passes uncompressed, shuffled table bytes to `Swift.decodeAtmosphereTable(...)` for mathematical unshuffling.
  6. Uploads bitmaps to Three.js `CubeTexture`s and `DataTexture` / `Data3DTexture`.
* **WebAssembly (Swift bridge via `AuraDecoding`):**
  * Never touches texture image bytes.
  * Contains **no compression/inflation dependencies** (keeping Wasm binary footprint small).
  * Exclusively performs SIMD-accelerated byte-plane deshuffling and PNG Up filter reversal on uncompressed byte buffers via `AtmosphereTableDecoder.decode(...)`.

### JavaScript decoding code

```typescript
export async function loadPlanetaryArchive(url: string): Promise<Map<string, PlanetaryBodyData>> {
    const response = await fetch(url);
    const arrayBuffer = await response.arrayBuffer();

    // Directly parse uncompressed Ion binary:
    const root = ion.load(new Uint8Array(arrayBuffer));
    const result = new Map<string, PlanetaryBodyData>();
    const planetsNode = root.get('planets');

    if (!planetsNode) {
        throw new Error(`Invalid archive at ${url}: missing 'planets' list`);
    }

    for (const entry of planetsNode.elements()) {
        const name = entry.get('name').stringValue();
        const surfaceNode = entry.get('surface');
        
        // Extract WebP face blobs directly without Wasm memory copying:
        const albedoBlobs = extractCubemapBlobs(surfaceNode.get('albedo'));
        const reliefBlobs = surfaceNode.get('relief') ? extractCubemapBlobs(surfaceNode.get('relief')) : null;

        // Decode WebP faces asynchronously on browser background threads:
        const albedoCube = await createCubeTextureFromBlobs(albedoBlobs, SRGBColorSpace);
        const reliefCube = reliefBlobs ? await createCubeTextureFromBlobs(reliefBlobs, LinearSRGBColorSpace) : null;

        // If atmosphere is present, decompress and unshuffle tables:
        let atmosphereData: PlanetaryAtmosphere | null = null;
        const atmoNode = entry.get('atmosphere');
        if (atmoNode) {
            atmosphereData = await decodeAtmosphere(name, atmoNode);
        }

        result.set(name, {
            parameters: extractParameters(entry.get('parameters')),
            albedoCube,
            reliefCube,
            atmosphere: atmosphereData,
        });
    }

    return result;
}

async function decodeAtmosphere(name: string, atmoNode: ion.dom.Value): Promise<PlanetaryAtmosphere> {
    const tablesNode = atmoNode.get('tables');

    async function decompressTable(tableNode: ion.dom.Value): Promise<{ data: Float32Array; width: number; height: number; depth: number }> {
        const width = tableNode.get('width').numberValue();
        const height = tableNode.get('height').numberValue();
        const depth = tableNode.get('depth')?.numberValue() ?? 1;
        const deflatedBlob = tableNode.get('data').uInt8ArrayValue();

        // 1. Decompress raw Deflate stream using browser-native DecompressionStream:
        const stream = new Response(deflatedBlob).body!.pipeThrough(
            new DecompressionStream('deflate') as unknown as ReadableWritablePair<Uint8Array, Uint8Array>
        );
        const decompressedShuffled = new Uint8Array(await new Response(stream).arrayBuffer());

        // 2. Pass uncompressed, shuffled bytes to Wasm for SIMD byte-plane deshuffling:
        const floatTexels = Swift.decodeAtmosphereTable(decompressedShuffled, width, height, depth);
        return { data: floatTexels, width, height, depth };
    }

    const [trans, scat, irrad] = await Promise.all([
        decompressTable(tablesNode.get('transmittance')),
        decompressTable(tablesNode.get('scattering')),
        decompressTable(tablesNode.get('irradiance')),
    ]);

    return {
        parameters: extractAtmosphereParameters(atmoNode.get('parameters')),
        tables: {
            transmittanceTable: createDataTexture(trans),
            scatteringTable: createData3DTexture(scat),
            irradianceTable: createDataTexture(irrad),
        }
    };
}

async function createCubeTextureFromBlobs(
    faces: Record<'px' | 'nx' | 'py' | 'ny' | 'pz' | 'nz', Uint8Array>,
    colorSpace: ColorSpace
): Promise<CubeTexture> {
    const keys: Array<'px' | 'nx' | 'py' | 'ny' | 'pz' | 'nz'> = ['px', 'nx', 'py', 'ny', 'pz', 'nz'];
    const bitmaps = await Promise.all(
        keys.map(async (key) => {
            const blob = new Blob([faces[key]], { type: 'image/webp' });
            return await createImageBitmap(blob);
        })
    );

    const texture = new CubeTexture(bitmaps);
    texture.colorSpace = colorSpace;
    texture.needsUpdate = true;
    return texture;
}
```

### Key performance benefits

1. **No whole-archive Gzip penalty:**  
   Zero decompression CPU overhead on multi-megabyte texture files.
2. **Zero Wasm memory amplification:**  
   Large WebP textures are decoded by the browser’s C++ image pipeline directly into GPU memory, avoiding copying images into or out of the WebAssembly heap.
3. **True parallel decoding:**  
   All 6 faces of the cubemap are decoded concurrently using native browser worker threads via `createImageBitmap`.
4. **Lightweight WebAssembly footprint:**  
   `AuraDecoding` in Wasm does not link or embed zlib/deflate code; decompression runs via browser-native streams in JavaScript.
