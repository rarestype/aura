struct TransmittanceTable: AtmosphereTable, Sendable {
    let context: AtmosphereContext
    var buffer: [Vector3<Double>]

    var size: Vector2<Int> {
        self.context.resolution.transmittance
    }
}

extension TransmittanceTable {
    // Transmittance to top
    var top: Top {
        .init(table: self)
    }

    // Transmittance to sun
    var sun: Sun {
        .init(table: self)
    }
}

// Single scattering
extension TransmittanceTable {
    subscript(
        r r: Double,
        μ μ: Double,
        d d: Double,
        intersectsGround intersectsGround: Bool
    ) -> Vector3<Double> {
        self.context.assert(r: r, μ: μ)
        Swift.assert(d >= 0)

        let q: Double = d * d + 2 * r * μ * d + r * r
        let rd: Double = self.context.clamp(r: .sqrt(q))
        let μd: Double = max(-1, min((r * μ + d) / rd, 1))
        if intersectsGround {
            let transmittance: Vector3<Double> = self.top[r: rd, μ: -μd] / self.top[r: r, μ: -μ]
            return .min(transmittance, .init(repeating: 1))
        } else {
            let transmittance: Vector3<Double> = self.top[r: r, μ: μ] / self.top[r: rd, μ: μd]
            return .min(transmittance, .init(repeating: 1))
        }
    }

    func singleScatteringIntegrand(
        r: Double,
        μ: Double,
        μs: Double,
        ν: Double,
        d: Double,
        intersectsGround: Bool
    ) -> (rayleigh: Vector3<Double>, mie: Vector3<Double>) {
        let q: Double = d * d + 2 * r * μ * d + r * r
        let rd: Double = self.context.clamp(r: .sqrt(q))
        let μsd: Double = max(-1, min((r * μs + d * ν) / rd, 1))
        let transmittance: Vector3<Double> =
        self[r: r, μ: μ, d: d, intersectsGround: intersectsGround] * self.sun[r: rd, μs: μsd]
        return (
            transmittance * self.context.rayleigh.density[
                altitude: rd - self.context.radius.bottom
            ],
            transmittance * self.context.mie.density[
                altitude: rd - self.context.radius.bottom
            ]
        )
    }

    // Integral
    func singleScattering(
        r: Double,
        μ: Double,
        μs: Double,
        ν: Double,
        intersectsGround: Bool,
        samples: Int = 50
    ) -> (rayleigh: Vector3<Double>, mie: Vector3<Double>) {
        self.context.assert(r: r, μ: μ)
        AtmosphereContext.assert(μs: μs, ν: ν)

        let distance: Double = self.context.distanceToBoundary(
            r: r,
            μ: μ,
            intersectsGround: intersectsGround
        ),
        Δx: Double = distance / .init(samples)
        // Perform integral
        var sum: (rayleigh: Vector3<Double>, mie: Vector3<Double>) = (.zero, .zero)
        for i: Int in 0 ... samples /* inclusive range because trapezoidal rule*/ {
            let d: Double = .init(i) * Δx
            let (rayleigh, mie): (Vector3<Double>, Vector3<Double>) =
            self.singleScatteringIntegrand(
                r: r, μ: μ, μs: μs, ν: ν, d: d,
                intersectsGround: intersectsGround
            )
            // Trapezoidal rule
            let w: Double = i == 0 || i == samples ? 0.5 : 1
            sum.rayleigh += rayleigh * w
            sum.mie      += mie * w
        }

        let irradiance: Vector3<Double> = self.context.irradiance
        return (
            sum.rayleigh * Δx * irradiance * self.context.rayleigh.scattering,
            sum.mie      * Δx * irradiance * self.context.mie.scattering
        )
    }

    func singleScattering(texel: Vector3<Double>) -> (
        rayleigh: Vector3<Double>,
        mie: Vector3<Double>
    ) {
        let (r, μ, μs, ν, intersectsGround): (
            r: Double,
            μ: Double,
            μs: Double,
            ν: Double,
            intersectsGround: Bool
        ) =
        self.context.scatteringTextureParameter(texel: texel)
        return self.singleScattering(
            r: r,
            μ: μ,
            μs: μs,
            ν: ν,
            intersectsGround: intersectsGround
        )
    }

    func directIrradiance(r: Double, μs: Double) -> Vector3<Double> {
        self.context.assert(r: r, μ: μs)

        let αs: Double = self.context.radius.sun
        let average: Double
        if μs <= -αs {
            average = 0
        } else if μs <   αs {
            let β: Double = μs + αs
            average = β * β / (4 * αs)
        } else {
            average = μs
        }

        return average * self.context.irradiance * self.top[r: r, μ: μs]
    }

    func directIrradiance(texel: Vector2<Double>) -> Vector3<Double> {
        let size: Vector2<Double> = .cast(self.context.resolution.irradiance)
        let (r, μs): (r: Double, μs: Double) = self.context.irradianceTextureParameter(
            texel / size
        )
        return self.directIrradiance(r: r, μs: μs)
    }
}

extension TransmittanceTable: CustomStringConvertible {
    var description: String {
        """
        Transmittance table [\(self.size.x), \(self.size.y)]
        {
        \((0 ..< self.size.y).map {
                (y: Int) in
                """
                    [\(y)]:
                \((0 ..< self.size.x).map {
                        (x: Int) in

                        let color: Vector3<Double> = self.buffer[y * self.size.x + x]
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
        }
        """
    }
}
