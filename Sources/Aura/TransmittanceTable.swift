struct TransmittanceTable: AtmosphereTable, Sendable {
    let atmosphere: Atmosphere
    var buffer: [Vector3<Double>]

    var size: Vector2<Int> {
        self.atmosphere.resolution.transmittance
    }

    // Transmittance to top
    var top: Top {
        .init(table: self)
    }

    struct Top {
        let table: TransmittanceTable

        subscript(r r: Double, μ μ: Double) -> Vector3<Double> {
            self.table.atmosphere.assert(r: r, μ: μ)
            let t: Vector2<Double> = self.table.atmosphere.transmittanceTextureCoordinate(
                r: r,
                μ: μ
            )
            return self.table[t]
        }
    }

    // Transmittance to sun
    var sun: Sun {
        .init(table: self)
    }

    struct Sun {
        let table: TransmittanceTable

        subscript(r r: Double, μs μs: Double) -> Vector3<Double> {
            let α: Double = self.table.atmosphere.radius.sun
            let sin: Double = self.table.atmosphere.radius.bottom / r,
            cos: Double = -.sqrt(max(0, 1 - sin * sin))
            return self.table.top[r: r, μ: μs] * Atmosphere.smoothstep(
                -sin * α,
                sin * α,
                t: μs - cos
            )
        }
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
        self.atmosphere.assert(r: r, μ: μ)
        Swift.assert(d >= 0)

        let q: Double = d * d + 2 * r * μ * d + r * r
        let rd: Double = self.atmosphere.clamp(r: .sqrt(q))
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
        let rd: Double = self.atmosphere.clamp(r: .sqrt(q))
        let μsd: Double = max(-1, min((r * μs + d * ν) / rd, 1))
        let transmittance: Vector3<Double> =
        self[r: r, μ: μ, d: d, intersectsGround: intersectsGround] * self.sun[r: rd, μs: μsd]
        return (
            transmittance * self.atmosphere.rayleigh.density[
                altitude: rd - self.atmosphere.radius.bottom
            ],
            transmittance * self.atmosphere.mie.density[
                altitude: rd - self.atmosphere.radius.bottom
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
        self.atmosphere.assert(r: r, μ: μ)
        Atmosphere.assert(μs: μs, ν: ν)
        let distance: Double = self.atmosphere.distanceToBoundary(
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

        let irradiance: Vector3<Double> = self.atmosphere.irradiance
        return (
            sum.rayleigh * Δx * irradiance * self.atmosphere.rayleigh.scattering,
            sum.mie      * Δx * irradiance * self.atmosphere.mie.scattering
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
        self.atmosphere.scatteringTextureParameter(texel: texel)
        return self.singleScattering(
            r: r,
            μ: μ,
            μs: μs,
            ν: ν,
            intersectsGround: intersectsGround
        )
    }

    func directIrradiance(r: Double, μs: Double) -> Vector3<Double> {
        self.atmosphere.assert(r: r, μ: μs)

        let αs: Double = self.atmosphere.radius.sun
        let average: Double
        if μs <= -αs {
            average = 0
        } else if μs <   αs {
            let β: Double = μs + αs
            average = β * β / (4 * αs)
        } else {
            average = μs
        }

        return average * self.atmosphere.irradiance * self.top[r: r, μ: μs]
    }

    func directIrradiance(texel: Vector2<Double>) -> Vector3<Double> {
        let size: Vector2<Double> = .cast(self.atmosphere.resolution.irradiance)
        let (r, μs): (r: Double, μs: Double) = self.atmosphere.irradianceTextureParameter(
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
