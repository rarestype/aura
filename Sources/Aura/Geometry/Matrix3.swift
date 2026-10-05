struct Matrix3<T>: Equatable where T: SIMDScalar {
    private var columns: (Vector3<T>, Vector3<T>, Vector3<T>)

    init(_ v0: Vector3<T>, _ v1: Vector3<T>, _ v2: Vector3<T>) {
        self.columns = (v0, v1, v2)
    }
}

extension Matrix3 {
    var transposed: Matrix3<T> {
        .init(
            .init(self.columns.0.x, self.columns.1.x, self.columns.2.x),
            .init(self.columns.0.y, self.columns.1.y, self.columns.2.y),
            .init(self.columns.0.z, self.columns.1.z, self.columns.2.z)
        )
    }

    var matrix2: Matrix2<T> {
        .init(self.columns.0.xy, self.columns.1.xy)
    }

    @inline(always) subscript(column: Int) -> Vector3<T> {
        get {
            switch column {
            case 0:
                return self.columns.0
            case 1:
                return self.columns.1
            case 2:
                return self.columns.2
            default:
                fatalError("Matrix column index out of range")
            }
        }
        set(value) {
            switch column {
            case 0:
                self.columns.0 = value
            case 1:
                self.columns.1 = value
            case 2:
                self.columns.2 = value
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }

    static func == (a: Self, b: Self) -> Bool {
        a.columns.0 == b.columns.0 && a.columns.1 == b.columns.1 && a.columns.2 == b.columns.2
    }
}

extension Matrix3 where T: Numeric {
    static var identity: Matrix3<T> {
        .init(
            .init(1, 0, 0),
            .init(0, 1, 0),
            .init(0, 0, 1)
        )
    }
}
extension Matrix3 where T: FixedWidthInteger {
    static func &>< (A: Matrix3<T>, v: Vector3<T>) -> Vector3<T> {
        A.columns.0 &* v.x &+ A.columns.1 &* v.y &+ A.columns.2 &* v.z
    }

    static func &>< (A: Matrix3<T>, B: Matrix3<T>) -> Matrix3<T> {
        .init(A &>< B.columns.0, A &>< B.columns.1, A &>< B.columns.2)
    }
}
extension Matrix3 where T: FloatingPoint {
    static func >< (A: Matrix3<T>, v: Vector3<T>) -> Vector3<T> {
        (A.columns.0 * v.x).addingProduct(A.columns.1, v.y).addingProduct(
            A.columns.2,
            v.z
        )
    }

    static func >< (A: Matrix3<T>, B: Matrix3<T>) -> Matrix3<T> {
        .init(A >< B.columns.0, A >< B.columns.1, A >< B.columns.2)
    }
}
