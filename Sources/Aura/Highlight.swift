enum Highlight {
    static var bold: String { "\u{1B}[1m" }
    static var reset: String { "\u{1B}[0m" }

    static func fg(_ color: (r: UInt8, g: UInt8, b: UInt8)?) -> String {
        if let color: (r: UInt8, g: UInt8, b: UInt8) = color {
            return "\u{1B}[38;2;\(color.r);\(color.g);\(color.b)m"
        } else {
            return "\u{1B}[39m"
        }
    }
    static func bg(_ color: (r: UInt8, g: UInt8, b: UInt8)?) -> String {
        if let color: (r: UInt8, g: UInt8, b: UInt8) = color {
            return "\u{1B}[48;2;\(color.r);\(color.g);\(color.b)m"
        } else {
            return "\u{1B}[49m"
        }
    }

    static func swatch(_ color: Vector3<Double>) -> String {
        let r: UInt8 = .init((.init(UInt8.max) * max(0, min(color.x, 1))).rounded()),
        g: UInt8 = .init((.init(UInt8.max) * max(0, min(color.y, 1))).rounded()),
        b: UInt8 = .init((.init(UInt8.max) * max(0, min(color.z, 1))).rounded())
        return """
        \(Self.bg((r, g, b)))\(
            color.sum / 3 < 0.5 ? Self.fg((.max, .max, .max)) : Self.fg((0, 0, 0))
        ) \(
            Self.pad("\(r)", left: 3)
        ), \(
            Self.pad("\(g)", left: 3)
        ), \(
            Self.pad("\(b)", left: 3)
        ) \(
            Self.fg(nil)
        )\(
            Self.bg(nil)
        )
        """
    }

    static func pad(_ string: String, left count: Int) -> String {
        .init(repeating: " ", count: max(0, count - string.count)) + string
    }
}
