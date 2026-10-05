extension SIMD4 where Scalar: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        .init(Scalar.sqrt(x.x), Scalar.sqrt(x.y), Scalar.sqrt(x.z), Scalar.sqrt(x.w))
    }
    static func log(_ x: Self) -> Self {
        .init(Scalar.log(x.x), Scalar.log(x.y), Scalar.log(x.z), Scalar.log(x.w))
    }
    static func exp(_ x: Self) -> Self {
        .init(Scalar.exp(x.x), Scalar.exp(x.y), Scalar.exp(x.z), Scalar.exp(x.w))
    }
    static func sin(_ x: Self) -> Self {
        .init(Scalar.sin(x.x), Scalar.sin(x.y), Scalar.sin(x.z), Scalar.sin(x.w))
    }
    static func cos(_ x: Self) -> Self {
        .init(Scalar.cos(x.x), Scalar.cos(x.y), Scalar.cos(x.z), Scalar.cos(x.w))
    }
    static func tan(_ x: Self) -> Self {
        .init(Scalar.tan(x.x), Scalar.tan(x.y), Scalar.tan(x.z), Scalar.tan(x.w))
    }
    static func asin(_ x: Self) -> Self {
        .init(Scalar.asin(x.x), Scalar.asin(x.y), Scalar.asin(x.z), Scalar.asin(x.w))
    }
    static func acos(_ x: Self) -> Self {
        .init(Scalar.acos(x.x), Scalar.acos(x.y), Scalar.acos(x.z), Scalar.acos(x.w))
    }
    static func atan(_ x: Self) -> Self {
        .init(Scalar.atan(x.x), Scalar.atan(x.y), Scalar.atan(x.z), Scalar.atan(x.w))
    }
}
