# Planetary appearance packaging specification

This specification defines the architecture and file formats for Aura 2.0 planetary appearance assets.

---

## 1. Overview

An `.aura` file is an uncompressed Amazon Ion binary archive that provides all visual and physical parameters required by the WebGL renderer to display one or more celestial bodies.

The format pursues six primary goals. First, it collapses up to 13 separate HTTP requests per body (six albedo faces, six relief normal faces, and one atmosphere table file) into a single network fetch. Second, it supports packing multiple coupled celestial bodies into a single archive, such as Earth and Moon together. Third, it standardizes exclusively on WebP for all surface texture faces. Fourth, because WebP images are already entropy-compressed, the `.aura` archive itself remains uncompressed; compression is applied only to atmosphere tables, which contain raw `Float32` arrays that compress by 80–90%. Fifth, JavaScript directly parses the Ion archive using `ion-js` and feeds WebP byte blobs to browser-native `createImageBitmap(blob)`, so texture bytes never touch WebAssembly memory. Sixth, the format separates heavy numerical physics computations from asset packaging via a build intermediate (`.atmo`), enabling visual texture iteration times under 50 milliseconds.

---

## 2. Units and coordinate systems

The system strictly delineates between astronomical simulation units and atmospheric radiative transfer units.

Atmosphere subsystem parameters use meters for distances (matching Bruneton 2017 radiative transfer equations), inverse meters for volumetric scattering coefficients, and watts per square meter for solar irradiance. Planetary geometry parameters use kilometers for body radius (standard astronomical catalog convention), radians for axial tilt, and dimensionless ratios for flattening and relief elevation scale.

In the WebGL renderer, astronomical radius in kilometers is converted to scene Astronomical Units by dividing by 149597870.7. The outer radius of the atmosphere rendering envelope is computed as `equatorialRadius × (radius_top / radius_bottom)`. Because both `radius_top` and `radius_bottom` are in meters, their units cancel cleanly.

---

## 3. Decoupled build pipeline

Atmospheric scattering simulation requires solving Bruneton's radiative transfer integral equations, which is compute-intensive. Texture packaging, by contrast, is purely I/O and Ion serialization.

To preserve sub-second iteration during art and shader development, the pipeline introduces a build intermediate for atmospheric scattering tables. The `aura bake` command performs the slow numerical solve and outputs `.atmo` files. The `aura pack` command then bundles these cached intermediates with WebP textures in tens of milliseconds. When texture art changes, developers re-run `aura pack`. When atmosphere parameters change, developers re-run `aura bake`. Bodies without atmospheres bypass the atmospheric solver entirely and only run `aura pack`.

---

## 4. File formats

The `.atmo` file is an uncompressed binary Amazon Ion structure produced by `aura bake`. It contains a single `Atmosphere` with physical parameters and three lookup tables. Each table's `bytes` field contains Deflate-compressed, byte-shuffled `Float32` data. The compression pipeline applies PNG Up filtering (delta encoding along the Y axis within each Z slice), then byte plane shuffling (transposing from `[volume][16 bytes]` to `[16 planes][volume]`), then Deflate compression via the LZ77 module from the swift-png package. Decompression reverses this sequence: inflate, unshuffle, unfilter. See `TableEncoder.swift` and `TableDecoder.swift` for implementation details.

The `.aura` file is an uncompressed binary Amazon Ion container representing an `AuraArchive`. It contains a version number (currently 2) and an array of bodies. Each body contains a name, spheroid parameters (radius, tilt, flattening, relief), an albedo cubemap with six WebP face blobs, an optional relief cubemap for normal mapping, and an optional atmosphere. The atmosphere is embedded directly rather than wrapped in `AtmosphereArchive` to eliminate redundant version and name fields; `AtmosphereArchive` is only used for `.atmo` intermediate files.

---

## 5. Module architecture

The codebase is split into three modules with clear responsibilities.

`AuraDecoding` provides mathematical table reconstruction (unfiltering and unshuffling) and is Wasm-compatible. It contains no compression dependencies to keep the WebAssembly binary small. The key type is `TableDecoder` with a `decode(bytes:count:)` method. This module is used by both the Swift host and the WebAssembly client.

`AuraEncoding` provides table compression (filtering, shuffling, and Deflate) for build-time use only. The key type is `TableEncoder` with an `encode(simd4:count:)` method. This module is not shipped to the client.

`Aura` provides high-level archive serialization, atmospheric computation, and decompression orchestration. Key types include `AuraArchive`, `AtmosphereArchive`, `Atmosphere`, and `Atmosphere.Table`. The module contains a `TableDecoder` extension that provides a `decompress()` convenience method combining LZ77 inflation with `TableDecoder.decode()`. This separation keeps LZ77 out of the Wasm binary while providing a clean API for host-side code.

---

## 6. Client integration

JavaScript running on the client thread fetches the `.aura` binary via HTTP GET, parses the uncompressed Ion document using `ion-js`, extracts WebP byte blobs, and passes them to `createImageBitmap(blob)` for off-thread browser-native decoding. For atmosphere tables, JavaScript decompresses Deflate blobs using browser-native `DecompressionStream('deflate')`, then passes the uncompressed shuffled bytes to `Swift.decodeAtmosphereTable(...)` via WebAssembly for mathematical unshuffling. Finally, JavaScript uploads the decoded bitmaps to Three.js textures.

WebAssembly, bridged through `AuraDecoding`, never touches texture image bytes and contains no compression or inflation dependencies. It exclusively performs SIMD-accelerated byte-plane deshuffling and PNG Up filter reversal on uncompressed byte buffers.

This architecture yields four key performance benefits. There is no whole-archive Gzip penalty, eliminating CPU overhead on multi-megabyte textures. There is zero Wasm memory amplification, since WebP images are decoded directly into GPU memory. All six cubemap faces decode concurrently via browser workers. The Wasm binary remains lightweight because it embeds no zlib or deflate code.

---

## 7. Table resolution parameters

The `AtmosphereParameters` struct contains both physical constants and resolution metadata. Physical constants used by the shader include radii, the minimum sun zenith angle cosine, scattering coefficients, and the Mie phase function parameter. Resolution metadata includes transmittance and irradiance dimensions, plus the four-dimensional scattering coordinate parametrization (R, μ, μs, ν).

The resolution metadata is retained because the 4D scattering coordinate parametrization depends on specific coordinate divisions. Retaining these explicit integers ensures shader coordinate mapping functions remain self-describing regardless of detail settings.

---

## 8. Binary blob encoding

All binary payloads, including cubemap faces and table buffers, are encoded as binary Amazon Ion blobs rather than integer sequences. In Swift, these byte collections must be wrapped using `Ion.BlobView<[UInt8], Ion.BlobType>` to ensure proper serialization.

---

## 9. Serialization boundary

`AuraArchive.deserialize(from:)` is a host-side Swift utility only. It is never called by the in-game WebAssembly engine, ensuring that large WebP byte arrays are never duplicated in the Wasm linear heap. The client parses Ion directly using `ion-js`.
