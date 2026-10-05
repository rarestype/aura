extension FloatingPoint {
    @inlinable mutating func clip(to interval: ClosedRange<Self>) {
        self = self.clipped(to: interval)
    }

    @inlinable func clipped(to interval: ClosedRange<Self>) -> Self {
        max(interval.lowerBound, min(self, interval.upperBound))
    }

    @inlinable static func interpolate(_ a: Self, _ b: Self, by t: Self) -> Self {
        a.addingProduct(a, -t).addingProduct(b, t)
    }
}
