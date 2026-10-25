extension AtmosphereParameters {
    /// A vector in an archive’s atmosphere parameters with the wrong number of components.
    enum VectorError: Error {
        case count(expected: Int, actual: Int)
    }
}
extension AtmosphereParameters.VectorError: CustomStringConvertible {
    var description: String {
        switch self {
        case .count(let expected, let actual):
            "expected a vector of \(expected) components, but found \(actual)"
        }
    }
}
