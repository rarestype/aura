extension FixedWidthInteger {
    /// Rounds up to the next power of two, with 0 rounding up to 1.
    /// Numbers that are already powers of two return themselves.
    @inlinable var nextPowerOfTwo: Self {
        1 &<< (Self.bitWidth &- (self &- 1).leadingZeroBitCount)
    }

    @inlinable var isPowerOfTwo: Bool {
        self > 0 && self & (self &- 1) == 0
    }
}
