struct Matrix4<T>: Equatable where T: SIMDScalar {
    private var columns: (Vector4<T>, Vector4<T>, Vector4<T>, Vector4<T>)

    init(_ v0: Vector4<T>, _ v1: Vector4<T>, _ v2: Vector4<T>, _ v3: Vector4<T>) {
        self.columns = (v0, v1, v2, v3)
    }
}

extension Matrix4 {
    var transposed: Matrix4<T> {
        .init(
            .init(self.columns.0.x, self.columns.1.x, self.columns.2.x, self.columns.3.x),
            .init(self.columns.0.y, self.columns.1.y, self.columns.2.y, self.columns.3.y),
            .init(self.columns.0.z, self.columns.1.z, self.columns.2.z, self.columns.3.z),
            .init(self.columns.0.w, self.columns.1.w, self.columns.2.w, self.columns.3.w)
        )
    }

    var matrix3: Matrix3<T> {
        .init(self.columns.0.xyz, self.columns.1.xyz, self.columns.2.xyz)
    }

    @inline(always) subscript(column: Int) -> Vector4<T> {
        get {
            switch column {
            case 0:
                return self.columns.0
            case 1:
                return self.columns.1
            case 2:
                return self.columns.2
            case 3:
                return self.columns.3
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
            case 3:
                self.columns.3 = value
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }

    static func == (a: Self, b: Self) -> Bool {
        a.columns.0 == b.columns.0 &&
        a.columns.1 == b.columns.1 &&
        a.columns.2 == b.columns.2 &&
        a.columns.3 == b.columns.3
    }
}

extension Matrix4 where T: Numeric {
    static var identity: Matrix4<T> {
        .init(
            .init(1, 0, 0, 0),
            .init(0, 1, 0, 0),
            .init(0, 0, 1, 0),
            .init(0, 0, 0, 1)
        )
    }
}
extension Matrix4 where T: FixedWidthInteger {
    static func &>< (A: Matrix4<T>, v: Vector4<T>) -> Vector4<T> {
        A.columns.0 &* v.x &+ A.columns.1 &* v.y &+ A.columns.2 &* v.z &+ A.columns.3 &* v.w
    }

    static func &>< (A: Matrix4<T>, B: Matrix4<T>) -> Matrix4<T> {
        .init(A &>< B.columns.0, A &>< B.columns.1, A &>< B.columns.2, A &>< B.columns.3)
    }
}
extension Matrix4 where T: FloatingPoint {
    static func >< (A: Matrix4<T>, v: Vector4<T>) -> Vector4<T> {
        (A.columns.0 * v.x).addingProduct(A.columns.1, v.y).addingProduct(
            A.columns.2,
            v.z
        ).addingProduct(
            A.columns.3,
            v.w
        )
    }

    static func >< (A: Matrix4<T>, B: Matrix4<T>) -> Matrix4<T> {
        .init(A >< B.columns.0, A >< B.columns.1, A >< B.columns.2, A >< B.columns.3)
    }
}
