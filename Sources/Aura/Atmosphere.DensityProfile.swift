extension Atmosphere {
    struct DensityProfile {
        private let layers: (Layer, Layer)

        init(_ monolayer: Layer) {
            self.layers.0 = .init(coefficients: (0, 0, 0), H: 1)
            self.layers.1 = monolayer
        }
        init(_ lower: Layer, _ upper: Layer) {
            self.layers.0 = lower
            self.layers.1 = upper
        }

        subscript(altitude altitude: Double) -> Double {
            let layer: Layer = altitude < self.layers.0.thickness
                ? self.layers.0
                : self.layers.1
            return layer[altitude: altitude]
        }
    }
}
