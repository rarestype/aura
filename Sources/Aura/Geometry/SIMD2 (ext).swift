extension SIMD2 where Scalar: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        .init(Scalar.sqrt(x.x), Scalar.sqrt(x.y))
    }
    static func log(_ x: Self) -> Self {
        .init(Scalar.log(x.x), Scalar.log(x.y))
    }
    static func exp(_ x: Self) -> Self {
        .init(Scalar.exp(x.x), Scalar.exp(x.y))
    }
    static func sin(_ x: Self) -> Self {
        .init(Scalar.sin(x.x), Scalar.sin(x.y))
    }
    static func cos(_ x: Self) -> Self {
        .init(Scalar.cos(x.x), Scalar.cos(x.y))
    }
    static func tan(_ x: Self) -> Self {
        .init(Scalar.tan(x.x), Scalar.tan(x.y))
    }
    static func asin(_ x: Self) -> Self {
        .init(Scalar.asin(x.x), Scalar.asin(x.y))
    }
    static func acos(_ x: Self) -> Self {
        .init(Scalar.acos(x.x), Scalar.acos(x.y))
    }
    static func atan(_ x: Self) -> Self {
        .init(Scalar.atan(x.x), Scalar.atan(x.y))
    }
}
