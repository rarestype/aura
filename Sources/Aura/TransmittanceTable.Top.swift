extension TransmittanceTable {
    struct Top {
        let table: TransmittanceTable
    }
}
extension TransmittanceTable.Top {
    subscript(r r: Double, μ μ: Double) -> Vector3<Double> {
        self.table.context.assert(r: r, μ: μ)
        let t: Vector2<Double> = self.table.context.transmittanceTextureCoordinate(
            r: r,
            μ: μ
        )
        return self.table[t]
    }
}
