extension AtmosphereContext {
    struct Scattering: Table, Sendable {
        let context: AtmosphereContext
        var buffer: [Vector3<Double>]

        var size: Vector3<Int> {
            self.context.resolution.scattering
        }
    }
}

extension AtmosphereContext.Scattering {
    subscript(
        r r: Double,
        μ μ: Double,
        μs μs: Double,
        ν ν: Double,
        intersectsGround intersectsGround: Bool
    ) -> Vector3<Double> {
        let t: Vector4<Double> = self.context.scatteringTextureCoordinate(
            r: r, μ: μ, μs: μs, ν: ν,
            intersectsGround: intersectsGround
        )
        let x: Double = t.x * .init(self.context.resolution.scattering4.N - 1)
        let i: Double = x.rounded(.down)
        let t3: (Vector3<Double>, Vector3<Double>) = (
            .init((i     + t.y) / .init(self.context.resolution.scattering4.N), t.z, t.w),
            .init((i + 1 + t.y) / .init(self.context.resolution.scattering4.N), t.z, t.w)
        )
        let u: Double = x - i
        return self[t3.0] * (1 - u) + self[t3.1] * u
    }

    // Called on multiple scattering texture
    subscript(
        r r: Double,
        μ μ: Double,
        μs μs: Double,
        ν ν: Double,
        intersectsGround intersectsGround: Bool,
        n n: Int,
        rayleigh rayleigh: Self,
        mie mie: Self
    ) -> Vector3<Double> {
        if n == 1 {
            let rayleigh: Vector3<Double> = rayleigh[
                r: r, μ: μ, μs: μs, ν: ν, intersectsGround: intersectsGround
            ]
            let mie: Vector3<Double> = mie[
                r: r, μ: μ, μs: μs, ν: ν, intersectsGround: intersectsGround
            ]
            return rayleigh * Rφ(ν) + mie * Mφ(ν, g: self.context.mie.g)
        } else {
            return self[r: r, μ: μ, μs: μs, ν: ν, intersectsGround: intersectsGround]
        }
    }

    func density(
        r: Double,
        μ: Double,
        μs: Double,
        ν: Double,
        n: Int,
        samples: Int = 16,
        transmittance: AtmosphereContext.Transmittance,
        rayleigh: Self,
        mie: Self,
        irradiance: AtmosphereContext.Irradiance
    ) -> Vector3<Double> {
        self.context.assert(r: r, μ: μ)
        AtmosphereContext.assert(μs: μs, ν: ν)

        Swift.assert(n > 1)

        let zenith: Vector3<Double> = .init(0, 0, 1)
        // View direction
        let ω: Vector3<Double>    = .init(.sqrt(1 - μ * μ), 0, μ)
        let sun: (x: Double, y: Double)
        sun.x               = ω.x == 0 ? 0 : (ν - μ * μs) / ω.x
        sun.y               = .sqrt(max(0, 1 - sun.x * sun.x - μs * μs))
        let ωs: Vector3<Double>   = .init(sun.x, sun.y, μs)

        let Δφ: Double = .pi / .init(samples),
        Δθ: Double = .pi / .init(samples)

        var combined: Vector3<Double> = .zero
        for l: Int in 0 ..< samples {
            let θ: Double = (.init(l) + 0.5) * Δθ
            var cos: (θ: Double, φ: Double),
            sin: (θ: Double, φ: Double)

            // Only theta-dependent
            cos.θ   = .cos(θ)
            sin.θ   = .sin(θ)
            let intersectsGround: Bool = self.context.intersectsGround(r: r, μ: cos.θ)
            var ground: (
                distance: Double,
                albedo: Vector3<Double>,
                transmittance: Vector3<Double>,
                irradiance: Vector3<Double>
            )
            if intersectsGround {
                ground.distance         = self.context.distanceToBottom(r: r, μ: cos.θ)
                ground.albedo           = self.context.ground
                ground.transmittance    = transmittance[
                    r: r,
                    μ: cos.θ,
                    d: ground.distance,
                    intersectsGround: true
                ]
            } else {
                ground.distance         = 0
                ground.albedo           = .zero
                ground.transmittance    = .zero
            }

            for m: Int in 0 ..< samples * 2 {
                let φ: Double             = (.init(m) + 0.5) * Δφ

                cos.φ               = .cos(φ)
                sin.φ               = .sin(φ)
                let ωi: Vector3<Double>   = .init(cos.φ * sin.θ, sin.φ * sin.θ, cos.θ)
                let Δωi: Double           = Δθ * Δφ * sin.θ

                let νs: Double            = ωs <> ωi
                let scattering: Vector3<Double> =
                self[
                    r: r, μ: ωi.z, μs: μs, ν: νs, intersectsGround: intersectsGround,
                    n: n - 1, rayleigh: rayleigh, mie: mie
                ]

                // Ground normal
                let g: Vector3<Double>    = (zenith * r + ωi * ground.distance).normalized()
                ground.irradiance = irradiance[r: self.context.radius.bottom, μs: g <> ωs]

                // Incident radiance
                let incident: Vector3<Double> =
                scattering + ground.albedo * ground.transmittance * ground.irradiance / .pi

                let νω: Double = ω <> ωi
                let density: (rayleigh: Double, mie: Double) = (
                    self.context.rayleigh.density[
                        altitude: r - self.context.radius.bottom
                    ],
                    self.context.mie.density[
                        altitude: r - self.context.radius.bottom
                    ]
                )
                let anisotropic: (rayleigh: Vector3<Double>, mie: Vector3<Double>) = (
                    density.rayleigh * Rφ(
                        νω
                    ) * self.context.rayleigh.scattering,
                    density.mie * Mφ(
                        νω,
                        g: self.context.mie.g
                    ) * self.context.mie.scattering
                )

                combined += Δωi * incident * (anisotropic.rayleigh + anisotropic.mie)
            }
        }
        return combined
    }

    // Integral, only call on a scattering density table
    func multipleScattering(
        r: Double,
        μ: Double,
        μs: Double,
        ν: Double,
        intersectsGround: Bool,
        samples: Int = 50,
        transmittance: AtmosphereContext.Transmittance
    ) -> Vector3<Double> {
        self.context.assert(r: r, μ: μ)
        AtmosphereContext.assert(μs: μs, ν: ν)

        let l: Double = self.context.distanceToBoundary(
            r: r,
            μ: μ,
            intersectsGround: intersectsGround
        ),
        Δx: Double = l / .init(samples)
        // Perform integral
        var sum: Vector3<Double> = .zero
        for i: Int in 0 ... samples /* inclusive range because trapezoidal rule*/ {
            let d: Double     = .init(i) * Δx

            let q: Double     = d * d + 2 * r * μ * d + r * r
            let rd: Double    = self.context.clamp(r: .sqrt(q))
            let μd: Double    = max(-1, min((r * μ  + d)     / rd, 1))
            let μsd: Double   = max(-1, min((r * μs + d * ν) / rd, 1))

            let Ss: Vector3<
                Double
            > = Δx * self[r: rd, μ: μd, μs: μsd, ν: ν, intersectsGround: intersectsGround] *
            transmittance[r: r,  μ: μ, d: d,           intersectsGround: intersectsGround]
            // Trapezoidal rule
            let w: Double = i == 0 || i == samples ? 0.5 : 1
            sum += Ss * w
        }

        return sum
    }

    func density(
        texel: Vector3<Double>,
        n: Int,
        transmittance: AtmosphereContext.Transmittance,
        rayleigh: Self,
        mie: Self,
        irradiance: AtmosphereContext.Irradiance
    ) -> Vector3<Double> {
        let (r, μ, μs, ν, _): (
            r: Double,
            μ: Double,
            μs: Double,
            ν: Double,
            intersectsGround: Bool
        ) =
        self.context.scatteringTextureParameter(texel: texel)
        return self.density(
            r: r, μ: μ, μs: μs, ν: ν, n: n,
            transmittance: transmittance, rayleigh: rayleigh, mie: mie, irradiance: irradiance
        )
    }

    func multipleScattering(
        texel: Vector3<Double>,
        transmittance: AtmosphereContext.Transmittance
    ) -> (radiance: Vector3<Double>, ν: Double) {
        let (r, μ, μs, ν, intersectsGround): (
            r: Double,
            μ: Double,
            μs: Double,
            ν: Double,
            intersectsGround: Bool
        ) =
        self.context.scatteringTextureParameter(texel: texel)
        let radiance: Vector3<Double> = self.multipleScattering(
            r: r, μ: μ, μs: μs, ν: ν,
            intersectsGround: intersectsGround, transmittance: transmittance
        )
        return (radiance, ν)
    }
}

// multiple scattering table
extension AtmosphereContext.Scattering {
    func indirectIrradiance(
        r: Double,
        μs: Double,
        n: Int,
        samples: Int = 32,
        rayleigh: Self,
        mie: Self
    ) -> Vector3<Double> {
        self.context.assert(r: r, μ: μs)
        Swift.assert(n >= 1)

        let Δφ: Double = .pi / .init(samples),
        Δθ: Double = .pi / .init(samples)
        let ωs: Vector3<Double>   = .init(.sqrt(1 - μs * μs), 0, μs)
        var sum: Vector3<Double>  = .zero
        for l: Int in 0 ..< samples / 2 {
            let θ: Double = (.init(l) + 0.5) * Δθ

            var cos: (θ: Double, φ: Double),
            sin: (θ: Double, φ: Double)

            // Only theta-dependent
            cos.θ   = .cos(θ)
            sin.θ   = .sin(θ)
            for m: Int in 0 ..< samples * 2 {
                let φ: Double = (.init(m) + 0.5) * Δφ
                cos.φ   = .cos(φ)
                sin.φ   = .sin(φ)

                let ω: Vector3<Double> = .init(cos.φ * sin.θ, sin.φ * sin.θ, cos.θ)
                let Δω: Double         = Δθ * Δφ * sin.θ

                let ν: Double = ω <> ωs
                sum    += Δω * ω.z * self[
                    r: r, μ: ω.z, μs: μs, ν: ν, intersectsGround: false,
                    n: n, rayleigh: rayleigh, mie: mie
                ]
            }
        }

        return sum
    }

    func indirectIrradiance(
        texel: Vector2<Double>,
        n: Int,
        rayleigh: Self,
        mie: Self
    ) -> Vector3<Double> {
        let size: Vector2<Double> = .cast(self.context.resolution.irradiance)
        let (r, μs): (r: Double, μs: Double) = self.context.irradianceTextureParameter(
            texel / size
        )
        return self.indirectIrradiance(r: r, μs: μs, n: n, rayleigh: rayleigh, mie: mie)
    }
}

extension AtmosphereContext.Scattering: CustomStringConvertible {
    var description: String {
        """
        Scattering table [\(self.size.x), \(self.size.y), \(self.size.z)]
        {
        \((0 ..< self.size.z).map {
                (z: Int) in
                """
                \((0 ..< self.size.y).map {
                        (y: Int) in
                        """
                            [\(z), \(y)]:
                        \((0 ..< self.size.x).map {
                                (x: Int) in
                                let color: Vector3<Double> = self.buffer[
                                    (
                                        z * self.size.y + y
                                    ) * self.size.x + x
                                ]
                                return """
                                        [\(Highlight.pad("\(x)", left: 3))]: \(
                                    Highlight.swatch(color)
                                ) \(
                                    color
                                )
                                """
                            }.joined(separator: "\n"))
                        """
                    }.joined(separator: "\n"))
                """
            }.joined(separator: "\n"))
        }
        """
    }
}
