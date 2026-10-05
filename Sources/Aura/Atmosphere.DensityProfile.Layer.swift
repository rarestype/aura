extension Atmosphere.DensityProfile {
    struct Layer {
        let thickness: Double
        let coefficient: (exponential: Double, linear: Double, constant: Double)
        let scale: Double

        init(
            thickness: Double = 0,
            coefficients: (exponential: Double, linear: Double, constant: Double),
            H: Double
        ) {
            self.thickness = thickness
            self.coefficient = coefficients
            self.scale = -1 / H
        }

        subscript(altitude altitude: Double) -> Double {
            let terms: (Double, Double, Double) = (
                self.coefficient.exponential * Double.exp(self.scale * altitude),
                self.coefficient.linear * altitude,
                self.coefficient.constant
            )
            return max(0, min(terms.0 + terms.1 + terms.2, 1))
        }
    }
}
