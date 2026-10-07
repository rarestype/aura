struct AtmosphereContext {
    let radius: (bottom: Double, top: Double, sun: Double) // sun is angular radius of disk

    let rayleigh: (density: DensityProfile, scattering: Vector3<Double>)
    let mie: (
        density: DensityProfile,
        scattering: Vector3<Double>,
        extinction: Vector3<Double>,
        g: Double
    )
    let absorption: (density: DensityProfile, extinction: Vector3<Double>)

    let irradiance: Vector3<Double> // solar irradiance
    let ground: Vector3<Double> // ground albedo

    let μsmin: Double // cosine of maximum sun zenith angle

    // Resolution parameters
    let resolution: (
        transmittance: Vector2<Int>,
        scattering: Vector3<Int>,
        scattering4: (R: Int, M: Int, MS: Int, N: Int),
        irradiance: Vector2<Int>
    )
}
extension AtmosphereContext {
    // Cap radius between bottom and top of atmosphere
    private var H: Double {
        .sqrt(self.radius.top * self.radius.top - self.radius.bottom * self.radius.bottom)
    }

    private static func discriminant(r: Double, μ: Double, h: Double) -> Double {
        r * r * (μ * μ - 1) + h * h
    }

    // This version seems to have less precision issues when used in
    // `scatteringTextureCoordinate(r:μ:μs:ν:intersectsGround:)` for some reason
    private static func discriminant(r: Double, rμ: Double, h: Double) -> Double {
        rμ * rμ - r * r + h * h
    }

    func distanceToTop(r: Double, μ: Double) -> Double {
        Swift.assert(r <= self.radius.top)
        Swift.assert(-1 ... 1 ~= μ)
        let d: Double = Self.discriminant(r: r, μ: μ, h: self.radius.top)
        return max(0, -r * μ + .sqrt(max(0, d)))
    }

    func distanceToBottom(r: Double, μ: Double) -> Double {
        Swift.assert(r >= self.radius.bottom)
        Swift.assert(-1 ... 1 ~= μ)
        let d: Double = Self.discriminant(r: r, μ: μ, h: self.radius.bottom)
        return max(0, -r * μ - .sqrt(max(0, d)))
    }

    func distanceToBoundary(r: Double, μ: Double, intersectsGround: Bool) -> Double {
        intersectsGround ? self.distanceToBottom(r: r, μ: μ) : self.distanceToTop(r: r, μ: μ)
    }

    func intersectsGround(r: Double, μ: Double) -> Bool {
        Swift.assert(r >= self.radius.bottom)
        Swift.assert(-1 ... 1 ~= μ)
        return μ < 0 && Self.discriminant(r: r, μ: μ, h: self.radius.bottom) >= 0
    }

    // Clamp to boundaries
    func clamp(r: Double) -> Double {
        max(self.radius.bottom, min(r, self.radius.top))
    }

    // Optical length to top of the atmosphere
    func opticalDepth(
        r: Double,
        μ: Double,
        profile: DensityProfile,
        samples: Int = 500
    ) -> Double {
        self.assert(r: r, μ: μ)
        let Δx: Double = self.distanceToTop(r: r, μ: μ) / .init(samples)
        // Perform integral
        var sum: Double = 0
        for i: Int in 0 ... samples /* inclusive range because trapezoidal rule*/ {
            let d: Double = .init(i) * Δx
            // Distance from sample point to planet center
            let r: Double = .sqrt((d + 2 * r * μ) * d + r * r)
            // Molecular number density
            let n: Double = profile[altitude: r - self.radius.bottom]
            // Trapezoidal rule
            let w: Double = i == 0 || i == samples ? 0.5 : 1

            sum += n * w
        }
        return sum * Δx
    }

    // Transmittance to top of atmosphere
    func transmittance(r: Double, μ: Double) -> Vector3<Double> {
        self.assert(r: r, μ: μ)
        let depth: (rayleigh: Double, mie: Double, absorption: Double) = (
            self.opticalDepth(r: r, μ: μ, profile: self.rayleigh.density),
            self.opticalDepth(r: r, μ: μ, profile: self.mie.density),
            self.opticalDepth(r: r, μ: μ, profile: self.absorption.density)
        )
        let terms: (Vector3<Double>, Vector3<Double>, Vector3<Double>) = (
            self.rayleigh.scattering    * depth.rayleigh,
            self.mie.extinction         * depth.mie,
            self.absorption.extinction  * depth.absorption
        )
        return .init(SIMD3<Double>.exp((-terms.0 - terms.1 - terms.2).storage))
    }

    func assert(r: Double, μ: Double) {
        Swift.assert(self.radius.bottom ... self.radius.top ~= r)
        Swift.assert(-1 ... 1 ~= μ)
    }

    static func assert(μs: Double, ν: Double) {
        Swift.assert(-1 ... 1 ~= μs)
        Swift.assert(-1 ... 1 ~= ν)
    }

    // Texture coordinate transforms
    private static func textureCoordinate(_ parameter: Double, resolution: Int) -> Double {
        let n: Double = .init(resolution)
        return (0.5 / n) + parameter * (1 - 1 / n)
    }

    private static func textureParameter(_ coordinate: Double, resolution: Int) -> Double {
        let n: Double = .init(resolution)
        return (coordinate - 0.5 / n) / (1 - 1 / n)
    }

    func transmittanceTextureCoordinate(r: Double, μ: Double) -> Vector2<Double> {
        self.assert(r: r, μ: μ)
        let ρ: Double = .sqrt(max(0, r * r - self.radius.bottom * self.radius.bottom))
        let H: Double = self.H
        let d: (Double, min: Double, max: Double) = (
            self.distanceToTop(r: r, μ: μ),
            self.radius.top - r,
            H + ρ
        )
        let x: (r: Double, μ: Double) = (
            ρ / H,
            (d.0 - d.min) / (d.max - d.min)
        )

        let u: Double = Self.textureCoordinate(
            x.μ,
            resolution: self.resolution.transmittance.x
        ),
        v: Double = Self.textureCoordinate(x.r, resolution: self.resolution.transmittance.y)
        return .init(u, v)
    }

    func transmittanceTextureParameter(_ coordinate: Vector2<Double>) -> (
        r: Double,
        μ: Double
    ) {
        Swift.assert(0 ... 1 ~= coordinate.x)
        Swift.assert(0 ... 1 ~= coordinate.y)
        let x: (r: Double, μ: Double) = (
            Self.textureParameter(coordinate.y, resolution: self.resolution.transmittance.y),
            Self.textureParameter(coordinate.x, resolution: self.resolution.transmittance.x)
        )
        let H: Double = self.H
        let ρ: Double = H * x.r
        let r: Double = .sqrt(ρ * ρ + self.radius.bottom * self.radius.bottom)
        let d: (Double, min: Double, max: Double)
        d.min = self.radius.top - r
        d.max = H + ρ
        d.0   = d.min + x.μ * (d.max - d.min)
        let μ: Double
        if d.0 == 0 {
            μ = 1
        } else {
            μ = (H * H - ρ * ρ - d.0 * d.0) / (2 * r * d.0)
        }

        return (r, max(-1, min(μ, 1)))
    }

    func scatteringTextureCoordinate(
        r: Double,
        μ: Double,
        μs: Double,
        ν: Double,
        intersectsGround: Bool
    ) -> Vector4<Double> {
        self.assert(r: r, μ: μ)
        Self.assert(μs: μs, ν: ν)

        let H: Double = self.H
        let ρ: Double = .sqrt(max(0, r * r - self.radius.bottom * self.radius.bottom))
        let u: (r: Double, μ: Double, μs: Double, ν: Double)
        u.r = Self.textureCoordinate(ρ / H, resolution: self.resolution.scattering4.R)

        // Better precision when using this variant
        let discriminant: Double = Self.discriminant(r: r, rμ: r * μ, h: self.radius.bottom)
        if intersectsGround {
            let d: (Double, min: Double, max: Double) = (
                -r * μ - .sqrt(max(0, discriminant)),
                min: r - self.radius.bottom,
                max: ρ
            )
            let x: Double = d.min == d.max ? 0 : (d.0 - d.min) / (d.max - d.min)
            u.μ = 0.5 - 0.5 * Self.textureCoordinate(
                x,
                resolution: self.resolution.scattering4.M / 2
            )
        } else {
            let d: (Double, min: Double, max: Double) = (
                -r * μ + .sqrt(max(0, discriminant + H * H)),
                min: self.radius.top - r,
                max: H + ρ
            )
            let x: Double = (d.0 - d.min) / (d.max - d.min)
            u.μ = 0.5 + 0.5 * Self.textureCoordinate(
                x,
                resolution: self.resolution.scattering4.M / 2
            )
        }

        let d: (Double, min: Double, max: Double) = (
            self.distanceToTop(r: self.radius.bottom, μ: μs),
            min: self.radius.top - self.radius.bottom,
            max: H
        )
        let x: Double = (d.0 - d.min) / (d.max - d.min)
        let A: Double = -2 * self.μsmin * self.radius.bottom / (d.max - d.min)
        u.μs    = Self.textureCoordinate(
            max(0, 1 - x / A) / (1 + x),
            resolution: self.resolution.scattering4.MS
        )
        u.ν     = (ν + 1) / 2
        return .init(u.ν, u.μs, u.μ, u.r)
    }

    func scatteringTextureParameter(_ coordinate: Vector4<Double>)
    -> (r: Double, μ: Double, μs: Double, ν: Double, intersectsGround: Bool) {
        Swift.assert(0 ... 1 ~= coordinate.x)
        Swift.assert(0 ... 1 ~= coordinate.y)
        Swift.assert(0 ... 1 ~= coordinate.z)
        Swift.assert(0 ... 1 ~= coordinate.w)

        let x: (r: Double, μ: Double, μs: Double)
        x.r  = Self.textureParameter(coordinate.w, resolution: self.resolution.scattering4.R)
        x.μs = Self.textureParameter(coordinate.y, resolution: self.resolution.scattering4.MS)
        let H: Double = self.H,
        ρ: Double = H * x.r,
        r: Double = .sqrt(ρ * ρ + self.radius.bottom * self.radius.bottom)

        let μ: Double,
        intersectsGround: Bool = coordinate.z < 0.5
        if intersectsGround {
            x.μ = Self.textureParameter(
                1 - 2 * coordinate.z,
                resolution: self.resolution.scattering4.M / 2
            )
            let d: (Double, min: Double, max: Double)
            d.min = r - self.radius.bottom
            d.max = ρ
            d.0   = d.min + x.μ * (d.max - d.min)

            μ = d.0 == 0 ? -1 : max(-1, min(-(ρ * ρ + d.0 * d.0) / (2 * r * d.0), 1))
        } else {
            x.μ = Self.textureParameter(
                2 * coordinate.z - 1,
                resolution: self.resolution.scattering4.M / 2
            )
            let d: (Double, min: Double, max: Double)
            d.min = self.radius.top - r
            d.max = H + ρ
            d.0   = d.min + x.μ * (d.max - d.min)

            μ = d.0 == 0 ? 1 : max(
                -1,
                min((H * H - ρ * ρ - d.0 * d.0) / (2 * r * d.0), 1)
            )
        }

        let d: (Double, min: Double, max: Double)
        d.min   = self.radius.top - self.radius.bottom
        d.max   = H
        let A: Double = -2 * self.μsmin * self.radius.bottom / (d.max - d.min),
        a: Double = (A - x.μs * A) / (1 + x.μs * A)
        d.0     = d.min + min(a, A) * (d.max - d.min)

        let μs: Double = d.0 == 0 ? 1 :
        max(-1, min((H * H - d.0 * d.0) / (2 * self.radius.bottom * d.0), 1))
        let ν: Double = max(-1, min(coordinate.x * 2 - 1, 1))

        return (r, μ, μs, ν, intersectsGround)
    }

    func scatteringTextureParameter(texel: Vector3<Double>)
    -> (r: Double, μ: Double, μs: Double, ν: Double, intersectsGround: Bool) {
        let size: Vector4<Double> = .cast(
            .init(
                self.resolution.scattering4.N - 1,
                self.resolution.scattering4.MS,
                self.resolution.scattering4.M,
                self.resolution.scattering4.R
            )
        )

        let MS: Double = .init(self.resolution.scattering4.MS)
        let texel: Vector4<Double> = .init(
            (texel.x / MS).rounded(.towardZero),
            texel.x.truncatingRemainder(dividingBy: MS),
            texel.y,
            texel.z
        )
        let (r, μ, μs, ν, intersectsGround): (
            r: Double,
            μ: Double,
            μs: Double,
            ν: Double,
            intersectsGround: Bool
        ) =
        self.scatteringTextureParameter(texel / size)
        let d: Double              = .sqrt((1 - μ * μ) * (1 - μs * μs))
        let n: (min: Double, max: Double) = (μ * μs - d, μ * μs + d)
        return (r: r, μ: μ, μs: μs, ν: max(n.min, min(ν, n.max)), intersectsGround)
    }

    func irradianceTextureCoordinate(r: Double, μs: Double) -> Vector2<Double> {
        self.assert(r: r, μ: μs)

        let x: (r: Double, μs: Double) = (
            (r - self.radius.bottom) / (self.radius.top - self.radius.bottom),
            (μs * 0.5 + 0.5)
        )

        let u: Double = Self.textureCoordinate(x.μs, resolution: self.resolution.irradiance.x),
        v: Double = Self.textureCoordinate(x.r,  resolution: self.resolution.irradiance.y)
        return .init(u, v)
    }

    func irradianceTextureParameter(_ coordinate: Vector2<Double>) -> (r: Double, μs: Double) {
        Swift.assert(0 ... 1 ~= coordinate.x)
        Swift.assert(0 ... 1 ~= coordinate.y)
        let x: (r: Double, μs: Double) = (
            Self.textureParameter(coordinate.y, resolution: self.resolution.irradiance.y),
            Self.textureParameter(coordinate.x, resolution: self.resolution.irradiance.x)
        )

        let r: Double = self.radius.bottom + x.r * (self.radius.top - self.radius.bottom)
        return (r, max(-1, min(2 * x.μs - 1, 1)))
    }

    func transmittance(texel: Vector2<Double>) -> Vector3<Double> {
        let size: Vector2<Double> = .cast(self.resolution.transmittance)
        let (r, μ): (Double, Double) = self.transmittanceTextureParameter(texel / size)
        return self.transmittance(r: r, μ: μ)
    }

    static func earth(
        resolutions resolution: (
            transmittance: Vector2<Int>,
            scattering: Vector4<Int>,
            irradiance: Vector2<Int>
        )
    ) -> Self {
        // Assert resolutions are even
        Swift.assert(resolution.transmittance / 2 &* 2 == resolution.transmittance)
        Swift.assert(resolution.scattering    / 2 &* 2 == resolution.scattering)
        Swift.assert(resolution.irradiance    / 2 &* 2 == resolution.irradiance)

        let λ: (min: Double, max: Double)    = (360, 840)
        let DU: Double                       = 2.687e20
        let irradiance: [Double] = [
            1.11776, 1.14259, 1.01249, 1.14716, 1.72765, 1.73054, 1.68870, 1.61253,
            1.91198, 2.03474, 2.02042, 2.02212, 1.93377, 1.95809, 1.91686, 1.82980,
            1.86850, 1.89310, 1.85149, 1.85040, 1.83410, 1.83450, 1.81470, 1.78158,
            1.75330, 1.69650, 1.68194, 1.64654, 1.60480, 1.52143, 1.55622, 1.51130,
            1.47400, 1.44820, 1.41018, 1.36775, 1.34188, 1.31429, 1.28303, 1.26758,
            1.23670, 1.20820, 1.18737, 1.14683, 1.12362, 1.10580, 1.07124, 1.04992
        ]
        let ozone: (σ: [Double], n: Double, layer: (DensityProfile.Layer, DensityProfile.Layer))
        ozone.σ = [
            1.180e-27, 2.182e-28, 2.818e-28, 6.636e-28, 1.527e-27, 2.763e-27, 5.520e-27,
            8.451e-27, 1.582e-26, 2.316e-26, 3.669e-26, 4.924e-26, 7.752e-26, 9.016e-26,
            1.480e-25, 1.602e-25, 2.139e-25, 2.755e-25, 3.091e-25, 3.500e-25, 4.266e-25,
            4.672e-25, 4.398e-25, 4.701e-25, 5.019e-25, 4.305e-25, 3.740e-25, 3.215e-25,
            2.662e-25, 2.238e-25, 1.852e-25, 1.473e-25, 1.209e-25, 9.423e-26, 7.455e-26,
            6.566e-26, 5.105e-26, 4.150e-26, 4.228e-26, 3.237e-26, 2.451e-26, 2.801e-26,
            2.534e-26, 1.624e-26, 1.465e-26, 2.078e-26, 1.383e-26, 7.105e-27
        ]
        ozone.n = 300 * DU / 15000

        let rayleigh: (Double, H: Double, layer: DensityProfile.Layer)
        rayleigh.0  = 1.24062e-6
        rayleigh.H  = 8000
        let mie: (
            α: Double,
            β: Double,
            albedo: Double,
            g: Double,
            H: Double,
            layer: DensityProfile.Layer
        )
        mie.α       = 0
        mie.β       = 5.328e-3
        mie.albedo  = 0.9
        mie.g       = 0.8
        mie.H       = 1200

        let ground: Double    = 0.1 // ground albedo
        let smax: Double      = 102 / 180 * .pi // max sun zenith angle

        // Atmosphere layers
        rayleigh.layer  = .init(coefficients: (1, 0, 0), H: rayleigh.H)
        mie.layer       = .init(coefficients: (1, 0, 0), H: mie.H)
        ozone.layer.0   = .init(
            thickness: 25000,
            coefficients: (0,  1/15000, -2/3),
            H: .infinity
        )
        ozone.layer.1   = .init(
            coefficients: (0, -1/15000,  8/3),
            H: .infinity
        )

        // Spectral interpolation
        func interpolate(λ l: Double, table: [Double]) -> Double {
            let count: Int = 48
            Swift.assert(table.count == count)
            let x: Double = (l - λ.min) / ((λ.max - λ.min) / .init(count)) - 0.5
            let i: (Int, Int)
            i.0 = max(0, min(.init(x), count - 1))
            i.1 =        min(i.0 + 1,  count - 1)
            let t: Double = x - .init(i.0)
            return table[i.0] * (1 - t) + table[i.1] * t
        }
        // Parameters as function of wavelength
        typealias Sample = (
            I: Double,
            Rs: Double,
            Ms: Double,
            Me: Double,
            Ae: Double,
            ground: Double
        )
        func sample(λ: Double) -> Sample {
            let I: Double = interpolate(λ: λ, table: irradiance),
            σ: Double = interpolate(λ: λ, table: ozone.σ)
            let Ae: Double = ozone.n * σ,
            Me: Double = mie.β / mie.H * Double.power(λ * 1e-3, to: -mie.α),
            Ms: Double = Me * mie.albedo,
            Rs: Double = rayleigh.0 / ((λ * λ) * (λ * λ) * 1e-12)
            return (I: I, Rs: Rs, Ms: Ms, Me: Me, Ae: Ae, ground: ground)
        }

        let RGB: (
            I: Vector3<Double>,
            Rs: Vector3<Double>,
            Ms: Vector3<Double>,
            Me: Vector3<Double>,
            Ae: Vector3<Double>,
            ground: Vector3<Double>
        )

        let R: Sample = sample(λ: 680),
        G: Sample = sample(λ: 550),
        B: Sample = sample(λ: 440)

        RGB.I       = .init(R.I,      G.I,      B.I)
        RGB.Rs      = .init(R.Rs,     G.Rs,     B.Rs)
        RGB.Ms      = .init(R.Ms,     G.Ms,     B.Ms)
        RGB.Me      = .init(R.Me,     G.Me,     B.Me)
        RGB.Ae      = .init(R.Ae,     G.Ae,     B.Ae)
        RGB.ground  = .init(R.ground, G.ground, B.ground)

        return .init(
            radius: (bottom: 6.36e6, top: 6.42e6, sun: 0.004675),
            rayleigh: (.init(rayleigh.layer), scattering: RGB.Rs),
            mie: (.init(mie.layer), scattering: RGB.Ms, extinction: RGB.Me, g: mie.g),
            absorption: (.init(ozone.layer.0, ozone.layer.1), extinction: RGB.Ae),
            irradiance: RGB.I,
            ground: RGB.ground,
            μsmin: .cos(smax),

            resolution: (
                resolution.transmittance,
                .init(
                    resolution.scattering.w * resolution.scattering.z,
                    resolution.scattering.y,
                    resolution.scattering.x
                ),
                (
                    R: resolution.scattering.x,
                    M: resolution.scattering.y,
                    MS: resolution.scattering.z,
                    N: resolution.scattering.w
                ),
                resolution.irradiance
            )
        )
    }
}

extension AtmosphereContext {
    func tables(
        workers: Int,
        N: Int = 4
    ) async -> (
        transmittance: TransmittanceTable,
        mie: ScatteringTable,
        scattering: ScatteringTable,
        irradiance: IrradianceTable
    ) {
        let texture: (
            irradiance: [Vector3<Double>],
            scattering: [(rayleigh: Vector3<Double>, mie: Vector3<Double>)],
            transmittance: [Vector3<Double>]
        )
        // Transmittance
        texture.transmittance   = await TransmittanceTable.mapIndices(
            size: self.resolution.transmittance,
            workers: workers
        ) {
            self.transmittance(texel: .cast($0) + 0.5)
        }
        let transmittance: TransmittanceTable = .init(
            context: self,
            buffer: texture.transmittance
        )

        // Direct irradiance
        texture.irradiance      = await IrradianceTable.mapIndices(
            size: self.resolution.irradiance,
            workers: workers
        ) {
            transmittance.directIrradiance(texel: .cast($0) + 0.5)
        }
        // Single scattering
        texture.scattering      = await ScatteringTable.mapIndices(
            size: self.resolution.scattering,
            workers: workers
        ) {
            transmittance.singleScattering(texel: .cast($0) + 0.5)
        }

        var Δirradiance: IrradianceTable = .init(context: self, buffer: texture.irradiance)
        let Δrayleigh: ScatteringTable = .init(
            context: self,
            buffer: texture.scattering.map(\.rayleigh)
        ),
        Δmie: ScatteringTable = .init(
            context: self,
            buffer: texture.scattering.map(\.mie)
        )

        // Compute successive scattering orders
        // For `n == 2`, `buffer` is never read anyway
        var Δscattering: ScatteringTable = .init(
            context: self,
            buffer: .init(repeating: .zero, count: self.resolution.scattering.wrappingVolume)
        )

        // Do not include direct irradiance in indirect irradiance accumulator
        var scattering: [Vector3<Double>] = Δrayleigh.buffer,
        irradiance: [Vector3<Double>] = .init(
            repeating: .zero,
            count: self.resolution.irradiance.wrappingVolume
        )
        for n: Int in 2 ... N {
            let previous: (
                scattering: ScatteringTable,
                irradiance: IrradianceTable
            ) = (Δscattering, Δirradiance)

            let texture: (
                irradiance: [Vector3<Double>],
                density: [Vector3<Double>],
                scattering: [(Vector3<Double>, ν: Double)]
            )

            texture.irradiance = await IrradianceTable.mapIndices(
                size: self.resolution.irradiance,
                workers: workers
            ) {
                previous.scattering.indirectIrradiance(
                    texel: .cast($0) + 0.5, n: n - 1,
                    rayleigh: Δrayleigh, mie: Δmie
                )
            }
            texture.density = await ScatteringTable.mapIndices(
                size: self.resolution.scattering,
                workers: workers
            ) {
                previous.scattering.density(
                    texel: .cast($0) + 0.5, n: n, transmittance: transmittance,
                    rayleigh: Δrayleigh, mie: Δmie, irradiance: previous.irradiance
                )
            }

            // Multiple scattering
            let density: ScatteringTable = .init(context: self, buffer: texture.density)
            texture.scattering = await ScatteringTable.mapIndices(
                size: self.resolution.scattering,
                workers: workers
            ) {
                density.multipleScattering(texel: .cast($0) + 0.5, transmittance: transmittance)
            }

            // Update and accumulate
            for i: Int in texture.scattering.indices {
                let (Δ, ν): (Vector3<Double>, Double) = texture.scattering[i]
                Δscattering.buffer[i] = Δ
                scattering[i] += Δ / Rφ(ν)
            }
            for i: Int in texture.irradiance.indices {
                let Δ: Vector3<Double> = texture.irradiance[i]
                Δirradiance.buffer[i] = Δ
                irradiance[i] += Δ
            }
        }

        return (
            transmittance: transmittance,
            mie: Δmie,
            scattering: .init(context: self, buffer: scattering),
            irradiance: .init(context: self, buffer: irradiance)
        )
    }
}

// Debug descriptions
extension AtmosphereContext: CustomStringConvertible {
    var description: String {
        """
        Atmosphere [\(self.resolution.transmittance), \(self.resolution.scattering4), \(
            self.resolution.irradiance
        )]
        {
            atmosphere: \(self.radius.bottom) ... \(self.radius.top) m
            sun size:   \(self.radius.sun * 180 / .pi)°

            Rs:         \(Highlight.swatch(self.rayleigh.scattering)    ) \(
            self.rayleigh.scattering
        )
            Ms:         \(Highlight.swatch(self.mie.scattering)         ) \(self.mie.scattering)
            Me:         \(Highlight.swatch(self.mie.extinction)         ) \(self.mie.extinction)
            Ae:         \(Highlight.swatch(self.absorption.extinction)  ) \(
            self.absorption.extinction
        )
            irradiance: \(Highlight.swatch(self.irradiance)             ) \(self.irradiance)
            ground:     \(Highlight.swatch(self.ground)                 ) \(self.ground)

            μsmin:      \(self.μsmin)
        }
        """
    }
}

extension AtmosphereContext {
    static func load(
        from config: AtmosphereConfig,
        resolutions resolution: (
            transmittance: Vector2<Int>,
            scattering: Vector4<Int>,
            irradiance: Vector2<Int>
        )
    ) -> Self {
        Swift.assert(resolution.transmittance / 2 &* 2 == resolution.transmittance)
        Swift.assert(resolution.scattering    / 2 &* 2 == resolution.scattering)
        Swift.assert(resolution.irradiance    / 2 &* 2 == resolution.irradiance)

        let smax: Double = config.max_sun_zenith_angle / 180.0 * .pi

        let rayleighLayer: DensityProfile.Layer = .init(
            coefficients: (1, 0, 0),
            H: config.rayleigh_scale_height
        )
        let rayleighScattering: Vector3<Double> = .init(
            config.rayleigh_scattering[0],
            config.rayleigh_scattering[1],
            config.rayleigh_scattering[2]
        )

        let mieLayer: DensityProfile.Layer = .init(
            coefficients: (1, 0, 0),
            H: config.mie_scale_height
        )
        let mieScattering: Vector3<Double> = .init(
            config.mie_scattering[0],
            config.mie_scattering[1],
            config.mie_scattering[2]
        )
        let mieExtinction: Vector3<Double>
        if let extinction: [Double] = config.mie_extinction, extinction.count == 3 {
            mieExtinction = .init(extinction[0], extinction[1], extinction[2])
        } else {
            let albedo: Double = config.mie_albedo ?? 0.9
            mieExtinction = mieScattering / albedo
        }

        let ozoneProfile: DensityProfile
        let ozoneExtinction: Vector3<Double>
        if let ozone: [Double] = config.ozone_extinction, ozone.count == 3 {
            let altitude: Double = config.ozone_altitude ?? 25000.0
            let thickness: Double = config.ozone_thickness ?? 15000.0
            let ozoneLayer0: DensityProfile.Layer = .init(
                thickness: altitude,
                coefficients: (0, 1.0 / thickness, -(altitude - thickness) / thickness),
                H: .infinity
            )
            let ozoneLayer1: DensityProfile.Layer = .init(
                coefficients: (0, -1.0 / thickness, (altitude + thickness) / thickness),
                H: .infinity
            )
            ozoneProfile = .init(ozoneLayer0, ozoneLayer1)
            ozoneExtinction = .init(ozone[0], ozone[1], ozone[2])
        } else {
            let zeroLayer: DensityProfile.Layer = .init(
                coefficients: (0, 0, 0),
                H: 1
            )
            ozoneProfile = .init(zeroLayer)
            ozoneExtinction = .zero
        }

        let solarIrradiance: Vector3<Double> = .init(
            config.solar_irradiance[0],
            config.solar_irradiance[1],
            config.solar_irradiance[2]
        )

        let groundAlbedo: Vector3<Double> = .init(
            config.ground_albedo[0],
            config.ground_albedo[1],
            config.ground_albedo[2]
        )

        return .init(
            radius: (
                bottom: config.radius_bottom,
                top: config.radius_top,
                sun: config.sun_angular_radius
            ),
            rayleigh: (.init(rayleighLayer), scattering: rayleighScattering),
            mie: (
                .init(mieLayer),
                scattering: mieScattering,
                extinction: mieExtinction,
                g: config.mie_g
            ),
            absorption: (ozoneProfile, extinction: ozoneExtinction),
            irradiance: solarIrradiance,
            ground: groundAlbedo,
            μsmin: .cos(smax),
            resolution: (
                resolution.transmittance,
                .init(
                    resolution.scattering.w * resolution.scattering.z,
                    resolution.scattering.y,
                    resolution.scattering.x
                ),
                (
                    R: resolution.scattering.x,
                    M: resolution.scattering.y,
                    MS: resolution.scattering.z,
                    N: resolution.scattering.w
                ),
                resolution.irradiance
            )
        )
    }
}
