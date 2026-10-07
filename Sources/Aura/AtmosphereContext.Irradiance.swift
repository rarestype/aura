extension AtmosphereContext {
    struct Irradiance: Table, Sendable {
        let context: AtmosphereContext
        var buffer: [Vector3<Double>]

        var size: Vector2<Int> {
            self.context.resolution.irradiance
        }
    }
}

extension AtmosphereContext.Irradiance {
    subscript(r r: Double, μs μs: Double) -> Vector3<Double> {
        let t: Vector2<Double> = self.context.irradianceTextureCoordinate(r: r, μs: μs)
        return self[t]
    }
}

extension AtmosphereContext.Irradiance: CustomStringConvertible {
    var description: String {
        """
        Irradiance table [\(self.size.x), \(self.size.y)]
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
