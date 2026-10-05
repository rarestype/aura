struct Vector2<Scalar>: Hashable where Scalar: SIMDScalar {
    var storage: SIMD2<Scalar>

    init(_ storage: SIMD2<Scalar>) {
        self.storage = storage
    }
}
extension Vector2: Sendable where Scalar: Sendable, Scalar.SIMD2Storage: Sendable {}
extension Vector2 {
    init(repeating repeatedValue: Scalar) {
        self.init(.init(repeatedValue, repeatedValue))
    }

    init(_ x: Scalar, _ y: Scalar) {
        self.init(.init(x, y))
    }
}
extension Vector2: CustomStringConvertible {
    var description: String { "\(self.tuple)" }
}
extension Vector2 {
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

    var tuple: (Scalar, Scalar) {
        (self.x, self.y)
    }

    subscript(index: Int) -> Scalar {
        self.storage[index]
    }

    func map<Result>(_ transform: (Scalar) throws -> Result) rethrows -> Vector2<Result>
        where Result: SIMDScalar {
        .init(try transform(self.x), try transform(self.y))
    }
}

extension Vector2 where Scalar: Comparable {
    static func min(_ a: Self, _ b: Self) -> Self {
        .init(Swift.min(a.x, b.x), Swift.min(a.y, b.y))
    }
    static func max(_ a: Self, _ b: Self) -> Self {
        .init(Swift.max(a.x, b.x), Swift.max(a.y, b.y))
    }
}

extension Vector2 where Scalar: BinaryInteger {
    static func cast<T>(_ v: Vector2<T>) -> Self where T: BinaryFloatingPoint {
        v.map(Scalar.init(_:))
    }
    static func cast<T>(_ v: Vector2<T>) -> Self where T: BinaryInteger {
        v.map(Scalar.init(_:))
    }
}
extension Vector2 where Scalar: FloatingPoint {
    static func cast<Source>(_ v: Vector2<Source>) -> Self where Source: BinaryInteger {
        v.map(Scalar.init(_:))
    }
}
extension Vector2 where Scalar: BinaryFloatingPoint {
    static func cast<Source>(_ v: Vector2<Source>) -> Self where Source: BinaryFloatingPoint {
        v.map(Scalar.init(_:))
    }
}

extension Vector2 where Scalar: FixedWidthInteger {
    static var zero: Vector2<Scalar> {
        .init(.zero)
    }

    static func &<< (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage &<< b.storage)
    }
    static func &<< (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage &<< b)
    }
    static func &<< (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a &<< b.storage)
    }

    static func &<<= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage &<<= b.storage
    }
    static func &<<= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage &<<= b
    }
    static func &>> (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage &>> b.storage)
    }
    static func &>> (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage &>> b)
    }
    static func &>> (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a &>> b.storage)
    }

    static func &>>= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage &>>= b.storage
    }
    static func &>>= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage &>>= b
    }
    static func &+ (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage &+ b.storage)
    }
    static func &+ (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage &+ b)
    }
    static func &+ (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a &+ b.storage)
    }

    static func &+= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage &+= b.storage
    }
    static func &+= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage &+= b
    }
    static func &- (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage &- b.storage)
    }
    static func &- (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage &- b)
    }
    static func &- (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a &- b.storage)
    }

    static func &-= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage &-= b.storage
    }
    static func &-= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage &-= b
    }
    static func &* (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage &* b.storage)
    }
    static func &* (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage &* b)
    }
    static func &* (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a &* b.storage)
    }

    static func &*= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage &*= b.storage
    }
    static func &*= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage &*= b
    }
    static func / (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage / b.storage)
    }
    static func / (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage / b)
    }
    static func / (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a / b.storage)
    }

    static func /= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage /= b.storage
    }
    static func /= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage /= b
    }
    static func % (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage % b.storage)
    }
    static func % (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage % b)
    }
    static func % (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a % b.storage)
    }

    static func %= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage %= b.storage
    }
    static func %= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage %= b
    }

    func roundedUp(exponent: Int) -> Vector2<Scalar> {
        let mask: Scalar                 = .max &<< exponent
        let truncated: SIMD2<Scalar>  = self.storage & mask
        let carry: SIMD2<Scalar> =
        SIMD2<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    }

    var wrappingSum: Scalar {
        self.x &+ self.y
    }
    var wrappingVolume: Scalar {
        self.x &* self.y
    }

    static func &<> (a: Vector2<Scalar>, b: Vector2<Scalar>) -> Scalar {
        (a &* b).wrappingSum
    }
}

extension Vector2 where Scalar: ExpressibleByIntegerLiteral {
    static var i: Self {
        .init(1, 0)
    }
    static var j: Self {
        .init(0, 1)
    }
}

extension Vector2 where Scalar: FloatingPoint {
    static var zero: Vector2<Scalar> {
        .init(.zero)
    }

    prefix static func - (operand: Vector2<Scalar>) -> Vector2<Scalar> {
        .init(-operand.storage)
    }

    static func + (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage + b.storage)
    }
    static func + (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage + b)
    }
    static func + (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a + b.storage)
    }

    static func += (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage += b.storage
    }
    static func += (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage += b
    }
    static func - (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage - b.storage)
    }
    static func - (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage - b)
    }
    static func - (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a - b.storage)
    }

    static func -= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage -= b.storage
    }
    static func -= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage -= b
    }
    static func * (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage * b.storage)
    }
    static func * (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage * b)
    }
    static func * (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a * b.storage)
    }

    static func *= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage *= b.storage
    }
    static func *= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage *= b
    }
    static func / (a: Vector2<Scalar>, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a.storage / b.storage)
    }
    static func / (a: Vector2<Scalar>, b: Scalar)
    -> Vector2<Scalar> {
        .init(a.storage / b)
    }
    static func / (a: Scalar, b: Vector2<Scalar>)
    -> Vector2<Scalar> {
        .init(a / b.storage)
    }

    static func /= (self: inout Vector2<Scalar>, b: Vector2<Scalar>) {
        self.storage /= b.storage
    }
    static func /= (self: inout Vector2<Scalar>, b: Scalar) {
        self.storage /= b
    }

    func addingProduct(_ a: Vector2<Scalar>, _ b: Vector2<Scalar>) -> Vector2<Scalar> {
        .init(self.storage.addingProduct(a.storage, b.storage))
    }
    func addingProduct(_ a: Scalar, _ b: Vector2<Scalar>) -> Vector2<Scalar> {
        .init(self.storage.addingProduct(a, b.storage))
    }
    func addingProduct(_ a: Vector2<Scalar>, _ b: Scalar) -> Vector2<Scalar> {
        .init(self.storage.addingProduct(a.storage, b))
    }
    mutating func addProduct(_ a: Vector2<Scalar>, _ b: Vector2<Scalar>) {
        self.storage.addProduct(a.storage, b.storage)
    }
    mutating func addProduct(_ a: Scalar, _ b: Vector2<Scalar>) {
        self.storage.addProduct(a, b.storage)
    }
    mutating func addProduct(_ a: Vector2<Scalar>, _ b: Scalar) {
        self.storage.addProduct(a.storage, b)
    }

    func squareRoot() -> Vector2<Scalar> {
        .init(self.storage.squareRoot())
    }

    func rounded(_ rule: FloatingPointRoundingRule) -> Vector2<Scalar> {
        .init(self.storage.rounded(rule))
    }
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self.storage.round(rule)
    }

    static func interpolate(_ a: Vector2<Scalar>, _ b: Vector2<Scalar>, by t: Scalar)
    -> Vector2<Scalar> {
        a.addingProduct(a, -t).addingProduct(b, t)
    }


    var sum: Scalar {
        self.x + self.y
    }
    var volume: Scalar {
        self.x * self.y
    }

    static func <> (a: Vector2<Scalar>, b: Vector2<Scalar>) -> Scalar {
        (a * b).sum
    }

    var length: Scalar {
        (self <> self).squareRoot()
    }

    mutating func normalize() {
        self /= self.length
    }
    func normalized() -> Vector2<Scalar> {
        self / self.length
    }

    static func <  (v: Vector2<Scalar>, r: Scalar) -> Bool {
        v <> v <  r
    }
    static func <= (v: Vector2<Scalar>, r: Scalar) -> Bool {
        v <> v <= r
    }
    static func ~~ (v: Vector2<Scalar>, r: Scalar) -> Bool {
        v <> v == r
    }
    static func !~ (v: Vector2<Scalar>, r: Scalar) -> Bool {
        v <> v != r
    }
    static func >= (v: Vector2<Scalar>, r: Scalar) -> Bool {
        v <> v >= r
    }
    static func >  (v: Vector2<Scalar>, r: Scalar) -> Bool {
        v <> v >  r
    }
}

extension Vector2 where Scalar: FixedWidthInteger {
    static func wrappingAbs(_ v: Self) -> Self {
        .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
    }
}
extension Vector2 where Scalar: FloatingPoint {
    static func abs(_ v: Self) -> Self {
        .init(v.storage.replacing(with: -v.storage, where: v.storage .< 0))
    }
}


extension Vector2 where Scalar: FixedWidthInteger {
    static func &>< (a: Vector2<Scalar>, b: Vector2<Scalar>) -> Scalar {
        a.x &* b.y &- b.x &* a.y
    }
}
extension Vector2 where Scalar: FloatingPoint {
    static func >< (a: Vector2<Scalar>, b: Vector2<Scalar>) -> Scalar {
        a.x * b.y - b.x * a.y
    }
}
