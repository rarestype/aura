struct IrradianceTable: AtmosphereTable, Sendable {
    let atmosphere: Atmosphere
    var buffer: [Vector3<Double>]

    var size: Vector2<Int> {
        self.atmosphere.resolution.irradiance
    }
}

extension IrradianceTable {
    subscript(r r: Double, μs μs: Double) -> Vector3<Double> {
        let t: Vector2<Double> = self.atmosphere.irradianceTextureCoordinate(r: r, μs: μs)
        return self[t]
    }
}

extension IrradianceTable: CustomStringConvertible {
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
