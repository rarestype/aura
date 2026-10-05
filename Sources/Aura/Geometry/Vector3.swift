struct Vector3<Scalar>: Hashable where Scalar: SIMDScalar {
    var storage: SIMD3<Scalar>

    init(_ storage: SIMD3<Scalar>) {
        self.storage = storage
    }
}
extension Vector3: Sendable where Scalar: Sendable, Scalar.SIMD4Storage: Sendable {}
extension Vector3 {
    init(repeating repeatedValue: Scalar) {
        self.init(.init(repeatedValue, repeatedValue, repeatedValue))
    }

    init(_ x: Scalar, _ y: Scalar, _ z: Scalar) {
        self.init(.init(x, y, z))
    }

    static func extend(_ body: Vector2<Scalar>, _ tail: Scalar)
    -> Vector3<Scalar> {
        .init(body.x, body.y, tail)
    }
}
extension Vector3: CustomStringConvertible {
    var description: String { "\(self.tuple)" }
}
extension Vector3 {
    var x: Scalar {
        get {
            self.storage.x
        }
        set(x) {
            self.storage.x = x
        }
    }
    var y: Scalar {
        get {
            self.storage.y
        }
        set(y) {
            self.storage.y = y
        }
    }
    var z: Scalar {
        get {
            self.storage.z
        }
        set(z) {
            self.storage.z = z
        }
    }

    var tuple: (Scalar, Scalar, Scalar) {
        (self.x, self.y, self.z)
    }

    var xy: Vector2<Scalar> {
        .init(self.x, self.y)
    }

    subscript(index: Int) -> Scalar {
        self.storage[index]
    }

    func map<Result>(_ transform: (Scalar) throws -> Result) rethrows -> Vector3<Result>
        where Result: SIMDScalar {
        .init(try transform(self.x), try transform(self.y), try transform(self.z))
    }
}

extension Vector3 where Scalar: Comparable {
    static func min(_ a: Self, _ b: Self) -> Self {
        .init(Swift.min(a.x, b.x), Swift.min(a.y, b.y), Swift.min(a.z, b.z))
    }
    static func max(_ a: Self, _ b: Self) -> Self {
        .init(Swift.max(a.x, b.x), Swift.max(a.y, b.y), Swift.max(a.z, b.z))
    }
}

extension Vector3 where Scalar: BinaryInteger {
    static func cast<T>(_ v: Vector3<T>) -> Self where T: BinaryFloatingPoint {
        v.map(Scalar.init(_:))
    }
    static func cast<T>(_ v: Vector3<T>) -> Self where T: BinaryInteger {
        v.map(Scalar.init(_:))
    }
}
extension Vector3 where Scalar: FloatingPoint {
    static func cast<Source>(_ v: Vector3<Source>) -> Self where Source: BinaryInteger {
        v.map(Scalar.init(_:))
    }
}
extension Vector3 where Scalar: BinaryFloatingPoint {
    static func cast<Source>(_ v: Vector3<Source>) -> Self where Source: BinaryFloatingPoint {
        v.map(Scalar.init(_:))
    }
}

extension Vector3 where Scalar: FixedWidthInteger {
    static var zero: Vector3<Scalar> {
        .init(.zero)
    }

    static func &<< (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage &<< b.storage)
    }
    static func &<< (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage &<< b)
    }
    static func &<< (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a &<< b.storage)
    }

    static func &<<= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage &<<= b.storage
    }
    static func &<<= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage &<<= b
    }
    static func &>> (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage &>> b.storage)
    }
    static func &>> (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage &>> b)
    }
    static func &>> (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a &>> b.storage)
    }

    static func &>>= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage &>>= b.storage
    }
    static func &>>= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage &>>= b
    }
    static func &+ (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage &+ b.storage)
    }
    static func &+ (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage &+ b)
    }
    static func &+ (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a &+ b.storage)
    }

    static func &+= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage &+= b.storage
    }
    static func &+= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage &+= b
    }
    static func &- (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage &- b.storage)
    }
    static func &- (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage &- b)
    }
    static func &- (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a &- b.storage)
    }

    static func &-= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage &-= b.storage
    }
    static func &-= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage &-= b
    }
    static func &* (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage &* b.storage)
    }
    static func &* (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage &* b)
    }
    static func &* (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a &* b.storage)
    }

    static func &*= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage &*= b.storage
    }
    static func &*= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage &*= b
    }
    static func / (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage / b.storage)
    }
    static func / (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage / b)
    }
    static func / (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a / b.storage)
    }

    static func /= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage /= b.storage
    }
    static func /= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage /= b
    }
    static func % (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage % b.storage)
    }
    static func % (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage % b)
    }
    static func % (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a % b.storage)
    }

    static func %= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage %= b.storage
    }
    static func %= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage %= b
    }

    func roundedUp(exponent: Int) -> Vector3<Scalar> {
        let mask: Scalar = .max &<< exponent
        let truncated: SIMD3<Scalar> = self.storage & mask
        let carry: SIMD3<Scalar> =
        SIMD3<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    }

    var wrappingSum: Scalar {
        self.x &+ self.y &+ self.z
    }
    var wrappingVolume: Scalar {
        self.x &* self.y &* self.z
    }

    static func &<> (a: Vector3<Scalar>, b: Vector3<Scalar>) -> Scalar {
        (a &* b).wrappingSum
    }
}

extension Vector3 where Scalar: ExpressibleByIntegerLiteral {
    static var i: Self {
        .init(1, 0, 0)
    }
    static var j: Self {
        .init(0, 1, 0)
    }
    static var k: Self {
        .init(0, 0, 1)
    }
}

extension Vector3 where Scalar: FloatingPoint {
    static var zero: Vector3<Scalar> {
        .init(.zero)
    }

    prefix static func - (operand: Vector3<Scalar>) -> Vector3<Scalar> {
        .init(-operand.storage)
    }

    static func + (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage + b.storage)
    }
    static func + (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage + b)
    }
    static func + (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a + b.storage)
    }

    static func += (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage += b.storage
    }
    static func += (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage += b
    }
    static func - (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage - b.storage)
    }
    static func - (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage - b)
    }
    static func - (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a - b.storage)
    }

    static func -= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage -= b.storage
    }
    static func -= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage -= b
    }
    static func * (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage * b.storage)
    }
    static func * (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage * b)
    }
    static func * (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a * b.storage)
    }

    static func *= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage *= b.storage
    }
    static func *= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage *= b
    }
    static func / (a: Vector3<Scalar>, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a.storage / b.storage)
    }
    static func / (a: Vector3<Scalar>, b: Scalar)
    -> Vector3<Scalar> {
        .init(a.storage / b)
    }
    static func / (a: Scalar, b: Vector3<Scalar>)
    -> Vector3<Scalar> {
        .init(a / b.storage)
    }

    static func /= (self: inout Vector3<Scalar>, b: Vector3<Scalar>) {
        self.storage /= b.storage
    }
    static func /= (self: inout Vector3<Scalar>, b: Scalar) {
        self.storage /= b
    }

    func addingProduct(_ a: Vector3<Scalar>, _ b: Vector3<Scalar>) -> Vector3<Scalar> {
        .init(self.storage.addingProduct(a.storage, b.storage))
    }
    func addingProduct(_ a: Scalar, _ b: Vector3<Scalar>) -> Vector3<Scalar> {
        .init(self.storage.addingProduct(a, b.storage))
    }
    func addingProduct(_ a: Vector3<Scalar>, _ b: Scalar) -> Vector3<Scalar> {
        .init(self.storage.addingProduct(a.storage, b))
    }
    mutating func addProduct(_ a: Vector3<Scalar>, _ b: Vector3<Scalar>) {
        self.storage.addProduct(a.storage, b.storage)
    }
    mutating func addProduct(_ a: Scalar, _ b: Vector3<Scalar>) {
        self.storage.addProduct(a, b.storage)
    }
    mutating func addProduct(_ a: Vector3<Scalar>, _ b: Scalar) {
        self.storage.addProduct(a.storage, b)
    }

    func squareRoot() -> Vector3<Scalar> {
        .init(self.storage.squareRoot())
    }

    func rounded(_ rule: FloatingPointRoundingRule) -> Vector3<Scalar> {
        .init(self.storage.rounded(rule))
    }
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self.storage.round(rule)
    }

    static func interpolate(_ a: Vector3<Scalar>, _ b: Vector3<Scalar>, by t: Scalar)
    -> Vector3<Scalar> {
        a.addingProduct(a, -t).addingProduct(b, t)
    }


    var sum: Scalar {
        self.x + self.y + self.z
    }
    var volume: Scalar {
        self.x * self.y * self.z
    }

    static func <> (a: Vector3<Scalar>, b: Vector3<Scalar>) -> Scalar {
        (a * b).sum
    }

    var length: Scalar {
        (self <> self).squareRoot()
    }

    mutating func normalize() {
        self /= self.length
    }
    func normalized() -> Vector3<Scalar> {
        self / self.length
    }

    static func <  (v: Vector3<Scalar>, r: Scalar) -> Bool {
        v <> v <  r
    }
    static func <= (v: Vector3<Scalar>, r: Scalar) -> Bool {
        v <> v <= r
    }
    static func ~~ (v: Vector3<Scalar>, r: Scalar) -> Bool {
        v <> v == r
    }
    static func !~ (v: Vector3<Scalar>, r: Scalar) -> Bool {
        v <> v != r
    }
    static func >= (v: Vector3<Scalar>, r: Scalar) -> Bool {
        v <> v >= r
    }
    static func >  (v: Vector3<Scalar>, r: Scalar) -> Bool {
        v <> v >  r
    }
}

extension Vector3 where Scalar: FixedWidthInteger {
    static func wrappingAbs(_ v: Self) -> Self {
        .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
    }
}
extension Vector3 where Scalar: FloatingPoint {
    static func abs(_ v: Self) -> Self {
        .init(v.storage.replacing(with: -v.storage, where: v.storage .< 0))
    }
}


extension Vector3 where Scalar: FixedWidthInteger {
    static func &>< (a: Vector3<Scalar>, b: Vector3<Scalar>) -> Vector3<Scalar> {
        .init(a.y, a.z, a.x) &* .init(b.z, b.x, b.y) &-
        .init(b.y, b.z, b.x) &* .init(a.z, a.x, a.y)
    }
}
extension Vector3 where Scalar: FloatingPoint {
    static func >< (a: Vector3<Scalar>, b: Vector3<Scalar>) -> Vector3<Scalar> {
        .init(a.y, a.z, a.x) * .init(b.z, b.x, b.y) -
        .init(b.y, b.z, b.x) * .init(a.z, a.x, a.y)
    }
}


extension Vector3 where Scalar: FloatingPoint & ElementaryFunctions {
    init(spherical: Spherical2<Scalar>) {
        let ll: Vector2<Scalar>  = .init(spherical.storage)
        let sin: Vector2<Scalar> = .init(.sin(ll.storage)),
        cos: Vector2<Scalar> = .init(.cos(ll.storage))
        self = .extend(.init(cos.y, sin.y) * sin.x, cos.x)
    }
}
