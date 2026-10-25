#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#endif

extension Float: ElementaryFunctions {
    static func sqrt(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.sqrt(x)
        #elseif canImport(Glibc)
        Glibc.sqrt(x)
        #elseif canImport(Musl)
        Musl.sqrt(x)
        #elseif canImport(WASILibc)
        WASILibc.sqrt(x)
        #endif
    }

    static func log(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.log(x)
        #elseif canImport(Glibc)
        Glibc.log(x)
        #elseif canImport(Musl)
        Musl.log(x)
        #elseif canImport(WASILibc)
        WASILibc.log(x)
        #endif
    }

    static func exp(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.exp(x)
        #elseif canImport(Glibc)
        Glibc.exp(x)
        #elseif canImport(Musl)
        Musl.exp(x)
        #elseif canImport(WASILibc)
        WASILibc.exp(x)
        #endif
    }

    static func sin(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.sin(x)
        #elseif canImport(Glibc)
        Glibc.sin(x)
        #elseif canImport(Musl)
        Musl.sin(x)
        #elseif canImport(WASILibc)
        WASILibc.sin(x)
        #endif
    }

    static func cos(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.cos(x)
        #elseif canImport(Glibc)
        Glibc.cos(x)
        #elseif canImport(Musl)
        Musl.cos(x)
        #elseif canImport(WASILibc)
        WASILibc.cos(x)
        #endif
    }

    static func tan(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.tan(x)
        #elseif canImport(Glibc)
        Glibc.tan(x)
        #elseif canImport(Musl)
        Musl.tan(x)
        #elseif canImport(WASILibc)
        WASILibc.tan(x)
        #endif
    }

    static func asin(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.asin(x)
        #elseif canImport(Glibc)
        Glibc.asin(x)
        #elseif canImport(Musl)
        Musl.asin(x)
        #elseif canImport(WASILibc)
        WASILibc.asin(x)
        #endif
    }

    static func acos(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.acos(x)
        #elseif canImport(Glibc)
        Glibc.acos(x)
        #elseif canImport(Musl)
        Musl.acos(x)
        #elseif canImport(WASILibc)
        WASILibc.acos(x)
        #endif
    }

    static func atan(_ x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.atan(x)
        #elseif canImport(Glibc)
        Glibc.atan(x)
        #elseif canImport(Musl)
        Musl.atan(x)
        #elseif canImport(WASILibc)
        WASILibc.atan(x)
        #endif
    }

    static func power(_ base: Self, to exponent: Self) -> Self {
        #if canImport(Darwin)
        Darwin.pow(base, exponent)
        #elseif canImport(Glibc)
        Glibc.pow(base, exponent)
        #elseif canImport(Musl)
        Musl.pow(base, exponent)
        #elseif canImport(WASILibc)
        WASILibc.pow(base, exponent)
        #endif
    }

    static func argument(y: Self, x: Self) -> Self {
        #if canImport(Darwin)
        Darwin.atan2(y, x)
        #elseif canImport(Glibc)
        Glibc.atan2(y, x)
        #elseif canImport(Musl)
        Musl.atan2(y, x)
        #elseif canImport(WASILibc)
        WASILibc.atan2(y, x)
        #endif
    }
}
