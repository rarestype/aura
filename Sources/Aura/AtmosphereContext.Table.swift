extension AtmosphereContext {
    protocol Table<Dimensions> {
        associatedtype Dimensions
        associatedtype Element

        var buffer: [Element] { get set }
        var size: Dimensions { get }
    }
}
extension AtmosphereContext.Table<Vector2<Int>> {
    subscript(y y: Int, x x: Int) -> Element {
        get {
            self.buffer[y * self.size.x + x]
        }
        set(value) {
            self.buffer[y * self.size.x + x] = value
        }
    }

    static func mapIndices<R>(
        size: Vector2<Int>,
        workers: Int,
        transform: @Sendable @escaping (Vector2<Int>) -> R
    ) async -> [R] where R: Sendable {
        guard workers > 1 else {
            var result: [R] = []
            result.reserveCapacity(size.wrappingVolume)
            for j: Int in 0 ..< size.y {
                for i: Int in 0 ..< size.x {
                    result.append(transform(.init(i, j)))
                }
            }
            return result
        }

        let totalRows: Int = size.y
        let workerCount: Int = max(1, min(workers, totalRows))
        let rowsPerWorker: Int = (totalRows + workerCount - 1) / workerCount

        return await withTaskGroup(
            of: (Int, [R]).self
        ) { (group: inout TaskGroup<(Int, [R])>) in
            for w: Int in 0 ..< workerCount {
                let startRow: Int = w * rowsPerWorker
                let endRow: Int = min(startRow + rowsPerWorker, totalRows)
                guard startRow < endRow else { continue }

                group.addTask {
                    let count: Int = (endRow - startRow) * size.x
                    var chunk: [R] = []
                    chunk.reserveCapacity(count)
                    for j: Int in startRow ..< endRow {
                        for i: Int in 0 ..< size.x {
                            chunk.append(transform(.init(i, j)))
                        }
                    }
                    return (w, chunk)
                }
            }

            var slices: [[R]] = .init(repeating: [], count: workerCount)
            for await (w, chunk) in group {
                slices[w] = chunk
            }

            var result: [R] = []
            result.reserveCapacity(size.wrappingVolume)
            for slice: [R] in slices {
                result.append(contentsOf: slice)
            }
            return result
        }
    }
}

extension AtmosphereContext.Table<Vector3<Int>> {
    subscript(z z: Int, y y: Int, x x: Int) -> Element {
        get {
            self.buffer[(z * self.size.y + y) * self.size.x + x]
        }
        set(value) {
            self.buffer[(z * self.size.y + y) * self.size.x + x] = value
        }
    }

    static func mapIndices<R>(
        size: Vector3<Int>,
        workers: Int,
        transform: @Sendable @escaping (Vector3<Int>) -> R
    ) async -> [R] where R: Sendable {
        guard workers > 1 else {
            var result: [R] = []
            result.reserveCapacity(size.wrappingVolume)
            for k: Int in 0 ..< size.z {
                for j: Int in 0 ..< size.y {
                    for i: Int in 0 ..< size.x {
                        result.append(transform(.init(i, j, k)))
                    }
                }
            }
            return result
        }

        let totalRows: Int = size.z * size.y
        let workerCount: Int = max(1, min(workers, totalRows))
        let rowsPerWorker: Int = (totalRows + workerCount - 1) / workerCount

        return await withTaskGroup(
            of: (Int, [R]).self
        ) { (group: inout TaskGroup<(Int, [R])>) in
            for w: Int in 0 ..< workerCount {
                let startRow: Int = w * rowsPerWorker
                let endRow: Int = min(startRow + rowsPerWorker, totalRows)
                guard startRow < endRow else { continue }

                group.addTask {
                    let count: Int = (endRow - startRow) * size.x
                    var chunk: [R] = []
                    chunk.reserveCapacity(count)
                    for r: Int in startRow ..< endRow {
                        let k: Int = r / size.y
                        let j: Int = r % size.y
                        for i: Int in 0 ..< size.x {
                            chunk.append(transform(.init(i, j, k)))
                        }
                    }
                    return (w, chunk)
                }
            }

            var slices: [[R]] = .init(repeating: [], count: workerCount)
            for await (w, chunk) in group {
                slices[w] = chunk
            }

            var result: [R] = []
            result.reserveCapacity(size.wrappingVolume)
            for slice: [R] in slices {
                result.append(contentsOf: slice)
            }
            return result
        }
    }
}

// Bilinear interpolation
extension AtmosphereContext.Table<Vector2<Int>> where Element == Vector3<Double> {
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
extension AtmosphereContext.Table<Vector3<Int>> where Element == Vector3<Double> {
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
