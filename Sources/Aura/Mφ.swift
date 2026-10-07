func Mφ(_ ν: Double, g: Double) -> Double {
    let k: Double = 3 / (8 * .pi) * (1 - g * g) / (2 + g * g)
    return k * (1 + ν * ν) / Double.power(1 + g * g - 2 * g * ν, to: 1.5)
}
