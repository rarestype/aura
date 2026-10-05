extension SIMD3 where Scalar: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        .init(Scalar.sqrt(x.x), Scalar.sqrt(x.y), Scalar.sqrt(x.z))
    }
    static func log(_ x: Self) -> Self {
        .init(Scalar.log(x.x), Scalar.log(x.y), Scalar.log(x.z))
    }
    static func exp(_ x: Self) -> Self {
        .init(Scalar.exp(x.x), Scalar.exp(x.y), Scalar.exp(x.z))
    }
    static func sin(_ x: Self) -> Self {
        .init(Scalar.sin(x.x), Scalar.sin(x.y), Scalar.sin(x.z))
    }
    static func cos(_ x: Self) -> Self {
        .init(Scalar.cos(x.x), Scalar.cos(x.y), Scalar.cos(x.z))
    }
    static func tan(_ x: Self) -> Self {
        .init(Scalar.tan(x.x), Scalar.tan(x.y), Scalar.tan(x.z))
    }
    static func asin(_ x: Self) -> Self {
        .init(Scalar.asin(x.x), Scalar.asin(x.y), Scalar.asin(x.z))
    }
    static func acos(_ x: Self) -> Self {
        .init(Scalar.acos(x.x), Scalar.acos(x.y), Scalar.acos(x.z))
    }
    static func atan(_ x: Self) -> Self {
        .init(Scalar.atan(x.x), Scalar.atan(x.y), Scalar.atan(x.z))
    }
}
