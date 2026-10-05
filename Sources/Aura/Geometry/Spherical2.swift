struct Spherical2<Scalar> where Scalar: SIMDScalar & FloatingPoint & ElementaryFunctions {
    var storage: SIMD2<Scalar>

    init(_ storage: SIMD2<Scalar>) {
        self.storage = storage
    }
}

extension Spherical2 {
    var colatitude: Scalar {
        get {
            self.storage.x
        }
        set(x) {
            self.storage.x = x
        }
    }
    var longitude: Scalar {
        get {
            self.storage.y
        }
        set(y) {
            self.storage.y = y
        }
    }

    init(_ colatitude: Scalar, _ longitude: Scalar) {
        self.init(.init(colatitude, longitude))
    }

    func map<Result>(_ transform: (Scalar) throws -> Result) rethrows -> Spherical2<Result>
        where Result: SIMDScalar {
        .init(try transform(self.colatitude), try transform(self.longitude))
    }
}

extension Spherical2 {
    static var zero: Spherical2<Scalar> {
        .init(.zero)
    }

    prefix static func - (operand: Spherical2<Scalar>) -> Spherical2<Scalar> {
        .init(-operand.storage)
    }

    static func + (a: Spherical2<Scalar>, b: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        .init(a.storage + b.storage)
    }
    static func + (a: Spherical2<Scalar>, b: Scalar)
    -> Spherical2<Scalar> {
        .init(a.storage + b)
    }
    static func + (a: Scalar, b: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        .init(a + b.storage)
    }

    static func += (self: inout Spherical2<Scalar>, b: Spherical2<Scalar>) {
        self.storage += b.storage
    }
    static func += (self: inout Spherical2<Scalar>, b: Scalar) {
        self.storage += b
    }
    static func - (a: Spherical2<Scalar>, b: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        .init(a.storage - b.storage)
    }
    static func - (a: Spherical2<Scalar>, b: Scalar)
    -> Spherical2<Scalar> {
        .init(a.storage - b)
    }
    static func - (a: Scalar, b: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        .init(a - b.storage)
    }

    static func -= (self: inout Spherical2<Scalar>, b: Spherical2<Scalar>) {
        self.storage -= b.storage
    }
    static func -= (self: inout Spherical2<Scalar>, b: Scalar) {
        self.storage -= b
    }
    static func * (a: Spherical2<Scalar>, b: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        .init(a.storage * b.storage)
    }
    static func * (a: Spherical2<Scalar>, b: Scalar)
    -> Spherical2<Scalar> {
        .init(a.storage * b)
    }
    static func * (a: Scalar, b: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        .init(a * b.storage)
    }

    static func *= (self: inout Spherical2<Scalar>, b: Spherical2<Scalar>) {
        self.storage *= b.storage
    }
    static func *= (self: inout Spherical2<Scalar>, b: Scalar) {
        self.storage *= b
    }
    static func / (a: Spherical2<Scalar>, b: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        .init(a.storage / b.storage)
    }
    static func / (a: Spherical2<Scalar>, b: Scalar)
    -> Spherical2<Scalar> {
        .init(a.storage / b)
    }
    static func / (a: Scalar, b: Spherical2<Scalar>)
    -> Spherical2<Scalar> {
        .init(a / b.storage)
    }

    static func /= (self: inout Spherical2<Scalar>, b: Spherical2<Scalar>) {
        self.storage /= b.storage
    }
    static func /= (self: inout Spherical2<Scalar>, b: Scalar) {
        self.storage /= b
    }

    func addingProduct(
        _ a: Spherical2<Scalar>,
        _ b: Spherical2<Scalar>
    ) -> Spherical2<Scalar> {
        .init(self.storage.addingProduct(a.storage, b.storage))
    }
    func addingProduct(_ a: Scalar, _ b: Spherical2<Scalar>) -> Spherical2<Scalar> {
        .init(self.storage.addingProduct(a, b.storage))
    }
    func addingProduct(_ a: Spherical2<Scalar>, _ b: Scalar) -> Spherical2<Scalar> {
        .init(self.storage.addingProduct(a.storage, b))
    }
    mutating func addProduct(_ a: Spherical2<Scalar>, _ b: Spherical2<Scalar>) {
        self.storage.addProduct(a.storage, b.storage)
    }
    mutating func addProduct(_ a: Scalar, _ b: Spherical2<Scalar>) {
        self.storage.addProduct(a, b.storage)
    }
    mutating func addProduct(_ a: Spherical2<Scalar>, _ b: Scalar) {
        self.storage.addProduct(a.storage, b)
    }

    func squareRoot() -> Spherical2<Scalar> {
        .init(self.storage.squareRoot())
    }

    func rounded(_ rule: FloatingPointRoundingRule) -> Spherical2<Scalar> {
        .init(self.storage.rounded(rule))
    }
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self.storage.round(rule)
    }
}

extension Spherical2 where Scalar: ElementaryFunctions {
    init(cartesian: Vector3<Scalar>) {
        let colatitude: Scalar = Scalar.acos(cartesian.z / cartesian.length)
        let longitude: Scalar  = Scalar.argument(y: cartesian.y, x: cartesian.x)
        self.init(colatitude, longitude)
    }

    init(normalized cartesian: Vector3<Scalar>) {
        let colatitude: Scalar = Scalar.acos(cartesian.z)
        let longitude: Scalar  = Scalar.argument(y: cartesian.y, x: cartesian.x)
        self.init(colatitude, longitude)
    }
}
