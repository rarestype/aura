protocol ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self
    static func log(_ x: Self) -> Self
    static func exp(_ x: Self) -> Self
    static func sin(_ x: Self) -> Self
    static func cos(_ x: Self) -> Self
    static func tan(_ x: Self) -> Self
    static func asin(_ x: Self) -> Self
    static func acos(_ x: Self) -> Self
    static func atan(_ x: Self) -> Self

    static func power(_ base: Self, to exponent: Self) -> Self
    static func argument(y: Self, x: Self) -> Self
}
