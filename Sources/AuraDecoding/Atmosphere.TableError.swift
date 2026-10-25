extension Atmosphere {
    enum TableError: Error {
        case size(expected: (x: Int, y: Int, z: Int), actual: Int)
    }
}
extension Atmosphere.TableError: CustomStringConvertible {
    var description: String {
        switch self {
        case .size(let expected, let actual):
            let voxels: Int = expected.x * expected.y * expected.z
            return """
            decoded \(actual) voxels, expected \(voxels) \
            (\(expected.x) × \(expected.y) × \(expected.z))
            """
        }
    }
}
