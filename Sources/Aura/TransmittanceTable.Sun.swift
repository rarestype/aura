extension TransmittanceTable {
    struct Sun {
        let table: TransmittanceTable
    }
}
extension TransmittanceTable.Sun {
    subscript(r r: Double, μs μs: Double) -> Vector3<Double> {
        let α: Double = self.table.context.radius.sun
        let sin: Double = self.table.context.radius.bottom / r
        let cos: Double = -.sqrt(max(0, 1 - sin * sin))
        return self.table.top[r: r, μ: μs] * (μs - cos).smoothstep(-sin * α, sin * α)
    }
}
