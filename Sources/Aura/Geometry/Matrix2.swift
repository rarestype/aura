struct Matrix2<T>: Equatable where T: SIMDScalar {
    private var columns: (Vector2<T>, Vector2<T>)

    init(_ v0: Vector2<T>, _ v1: Vector2<T>) {
        self.columns = (v0, v1)
    }
}

extension Matrix2 {
    var transposed: Matrix2<T> {
        .init(
            .init(self.columns.0.x, self.columns.1.x),
            .init(self.columns.0.y, self.columns.1.y)
        )
    }


    @inline(always) subscript(column: Int) -> Vector2<T> {
        get {
            switch column {
            case 0:
                return self.columns.0
            case 1:
                return self.columns.1
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
            default:
                fatalError("Matrix column index out of range")
            }
        }
    }

    static func == (a: Self, b: Self) -> Bool {
        a.columns.0 == b.columns.0 && a.columns.1 == b.columns.1
    }
}

extension Matrix2 where T: Numeric {
    static var identity: Matrix2<T> {
        .init(
            .init(1, 0),
            .init(0, 1)
        )
    }
}
extension Matrix2 where T: FixedWidthInteger {
    static func &>< (A: Matrix2<T>, v: Vector2<T>) -> Vector2<T> {
        A.columns.0 &* v.x &+ A.columns.1 &* v.y
    }

    static func &>< (A: Matrix2<T>, B: Matrix2<T>) -> Matrix2<T> {
        .init(A &>< B.columns.0, A &>< B.columns.1)
    }
}
extension Matrix2 where T: FloatingPoint {
    static func >< (A: Matrix2<T>, v: Vector2<T>) -> Vector2<T> {
        (A.columns.0 * v.x).addingProduct(A.columns.1, v.y)
    }

    static func >< (A: Matrix2<T>, B: Matrix2<T>) -> Matrix2<T> {
        .init(A >< B.columns.0, A >< B.columns.1)
    }
}

extension Matrix2 where T: FloatingPoint {
    func inversed() -> Self {
        let a: T = self.columns.0.x,
        b: T = self.columns.1.x,
        c: T = self.columns.0.y,
        d: T = self.columns.1.y

        let determinant: T = 1 / (a * d - b * c)
        return .init(determinant * .init(d, -c), determinant * .init(-b, a))
    }
}
