extension AtmosphereContext.Transmittance {
    struct Top {
        let table: AtmosphereContext.Transmittance
    }
}
extension AtmosphereContext.Transmittance.Top {
    subscript(r r: Double, μ μ: Double) -> Vector3<Double> {
        self.table.context.assert(r: r, μ: μ)
        let t: Vector2<Double> = self.table.context.transmittanceTextureCoordinate(
            r: r,
            μ: μ
        )
        return self.table[t]
    }
}
