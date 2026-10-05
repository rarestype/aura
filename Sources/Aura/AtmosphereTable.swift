protocol AtmosphereTable<Dimensions> {
    associatedtype Dimensions
    associatedtype Element

    var atmosphere: Atmosphere { get }
    var buffer: [Element] { get set }
    var size: Dimensions { get }
}
extension AtmosphereTable<Vector2<Int>> {
    subscript(y y: Int, x x: Int) -> Element {
        get {
            self.buffer[y * self.size.x + x]
        }
        set(value) {
            self.buffer[y * self.size.x + x] = value
        }
    }

    // static func mapIndices<R>(
    //     size: Vector2<Int>,
    //     transform: @Sendable (Vector2<Int>) -> R
    // ) -> [R] {
    //     .init(unsafeUninitializedCapacity: size.wrappingVolume) { buffer, initializedCount in
    //         guard let base: UnsafeMutablePointer<R> = buffer.baseAddress else {
    //             initializedCount = 0
    //             return
    //         }
    //         nonisolated(unsafe) let destination: UnsafeMutablePointer<R> = base
    //         DispatchQueue.concurrentPerform(iterations: size.y) { j in
    //             let rowOffset: Int = j * size.x
    //             for i: Int in 0 ..< size.x {
    //                 destination[rowOffset + i] = transform(.init(i, j))
    //             }
    //         }
    //         initializedCount = size.wrappingVolume
    //     }
    // }

    static func mapIndices<R>(
        size: Vector2<Int>,
        transform: (Vector2<Int>) throws -> R
    ) rethrows -> [R] {
        try .init(unsafeUninitializedCapacity: size.wrappingVolume) {
            for j: Int in 0 ..< size.y {
                for i: Int in 0 ..< size.x {
                    $0[j * size.x + i] = try transform(.init(i, j))
                }
            }
            $1 = size.wrappingVolume
        }
    }
}

extension AtmosphereTable<Vector3<Int>> {
    subscript(z z: Int, y y: Int, x x: Int) -> Element {
        get {
            self.buffer[(z * self.size.y + y) * self.size.x + x]
        }
        set(value) {
            self.buffer[(z * self.size.y + y) * self.size.x + x] = value
        }
    }

    // static func mapIndices<R>(
    //     size: Vector3<Int>,
    //     transform: @Sendable (Vector3<Int>) -> R
    // ) -> [R] {
    //     let rowCount: Int = size.z * size.y
    //     return .init(unsafeUninitializedCapacity: size.wrappingVolume) { buffer, initializedCount in
    //         guard let base: UnsafeMutablePointer<R> = buffer.baseAddress else {
    //             initializedCount = 0
    //             return
    //         }
    //         nonisolated(unsafe) let destination: UnsafeMutablePointer<R> = base
    //         DispatchQueue.concurrentPerform(iterations: rowCount) { rowIndex in
    //             let k: Int = rowIndex / size.y
    //             let j: Int = rowIndex % size.y
    //             let rowOffset: Int = rowIndex * size.x
    //             for i: Int in 0 ..< size.x {
    //                 destination[rowOffset + i] = transform(.init(i, j, k))
    //             }
    //         }
    //         initializedCount = size.wrappingVolume
    //     }
    // }

    static func mapIndices<R>(
        size: Vector3<Int>,
        transform: (Vector3<Int>) throws -> R
    ) rethrows -> [R] {
        try .init(unsafeUninitializedCapacity: size.wrappingVolume) {
            for k: Int in 0 ..< size.z {
                for j: Int in 0 ..< size.y {
                    for i: Int in 0 ..< size.x {
                        $0[(k * size.y + j) * size.x + i] = try transform(.init(i, j, k))
                    }
                }
            }
            $1 = size.wrappingVolume
        }
    }
}

// Bilinear interpolation
extension AtmosphereTable<Vector2<Int>> where Element == Vector3<Double> {
    subscript(t: Vector2<Double>) -> Vector3<Double> {
        let T: Vector2<Double> = t * .cast(self.size) - 0.5
        let i: (Int, Int),
        j: (Int, Int)
        i.0 = max(0, min(.init(T.x), self.size.x - 1))
        i.1 =        min(i.0 + 1,    self.size.x - 1)
        j.0 = max(0, min(.init(T.y), self.size.y - 1))
        j.1 =        min(j.0 + 1,    self.size.y - 1)
        let (u, v): (Double, Double) = (T.x - T.x.rounded(.down), T.y - T.y.rounded(.down))
        let y: (Vector3<Double>, Vector3<Double>) = (
            self[y: j.0, x: i.0] * (1 - u) + self[y: j.0, x: i.1] * u,
            self[y: j.1, x: i.0] * (1 - u) + self[y: j.1, x: i.1] * u
        )
        return y.0 * (1 - v) + y.1 * v
    }
}

// Trilinear interpolation
extension AtmosphereTable<Vector3<Int>> where Element == Vector3<Double> {
    subscript(t: Vector3<Double>) -> Vector3<Double> {
        let T: Vector3<Double> = t * .cast(self.size) - 0.5
        let i: (Int, Int)
        let j: (Int, Int)
        let k: (Int, Int)
        i.0 = max(0, min(.init(T.x), self.size.x - 1))
        i.1 =        min(i.0 + 1,    self.size.x - 1)
        j.0 = max(0, min(.init(T.y), self.size.y - 1))
        j.1 =        min(j.0 + 1,    self.size.y - 1)
        k.0 = max(0, min(.init(T.z), self.size.z - 1))
        k.1 =        min(k.0 + 1,    self.size.z - 1)
        let u: (Double, Double, Double) = (
            T.x - T.x.rounded(.down),
            T.y - T.y.rounded(.down),
            T.z - T.z.rounded(.down)
        )
        let y: ((Vector3<Double>, Vector3<Double>), (Vector3<Double>, Vector3<Double>)) = (
            (
                self[z: k.0, y: j.0, x: i.0] * (1 - u.0) + self[z: k.0, y: j.0, x: i.1] * u.0,
                self[z: k.0, y: j.1, x: i.0] * (1 - u.0) + self[z: k.0, y: j.1, x: i.1] * u.0
            ),
            (
                self[z: k.1, y: j.0, x: i.0] * (1 - u.0) + self[z: k.1, y: j.0, x: i.1] * u.0,
                self[z: k.1, y: j.1, x: i.0] * (1 - u.0) + self[z: k.1, y: j.1, x: i.1] * u.0
            )
        )
        let z: (Vector3<Double>, Vector3<Double>) = (
            y.0.0 * (1 - u.1) + y.0.1 * u.1,
            y.1.0 * (1 - u.1) + y.1.1 * u.1
        )
        return z.0 * (1 - u.2) + z.1 * u.2
    }
}
