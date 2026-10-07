public import Ion

@frozen @usableFromInline struct Vector4<Scalar>: Hashable where Scalar: SIMDScalar {
    @usableFromInline var storage: SIMD4<Scalar>

    init(_ storage: SIMD4<Scalar>) {
        self.storage = storage
    }
}
extension Vector4: Sendable where Scalar: Sendable, Scalar.SIMD4Storage: Sendable {}
extension Vector4 {
    init(repeating repeatedValue: Scalar) {
        self.init(.init(repeatedValue, repeatedValue, repeatedValue, repeatedValue))
    }

    init(_ x: Scalar, _ y: Scalar, _ z: Scalar, _ w: Scalar) {
        self.init(.init(x, y, z, w))
    }

    static func extend(_ body: Vector3<Scalar>, _ tail: Scalar)
    -> Vector4<Scalar> {
        .init(body.x, body.y, body.z, tail)
    }
}
extension Vector4: CustomStringConvertible {
    @inlinable var description: String { "\(self.tuple)" }
}
extension Vector4 {
    @inlinable var x: Scalar {
        get {
            self.storage.x
        }
        set(x) {
            self.storage.x = x
        }
    }
    @inlinable var y: Scalar {
        get {
            self.storage.y
        }
        set(y) {
            self.storage.y = y
        }
    }
    @inlinable var z: Scalar {
        get {
            self.storage.z
        }
        set(z) {
            self.storage.z = z
        }
    }
    @inlinable var w: Scalar {
        get {
            self.storage.w
        }
        set(w) {
            self.storage.w = w
        }
    }

    @inlinable var tuple: (Scalar, Scalar, Scalar, Scalar) {
        (self.x, self.y, self.z, self.w)
    }

    var xy: Vector2<Scalar> {
        .init(self.x, self.y)
    }
    var xyz: Vector3<Scalar> {
        .init(self.x, self.y, self.z)
    }

    subscript(index: Int) -> Scalar {
        self.storage[index]
    }

    func map<Result>(_ transform: (Scalar) throws -> Result) rethrows -> Vector4<Result>
        where Result: SIMDScalar {
        .init(
            try transform(self.x),
            try transform(self.y),
            try transform(self.z),
            try transform(self.w)
        )
    }
}

extension Vector4 where Scalar: Comparable {
    static func min(_ a: Self, _ b: Self) -> Self {
        .init(
            Swift.min(a.x, b.x),
            Swift.min(a.y, b.y),
            Swift.min(a.z, b.z),
            Swift.min(a.w, b.w)
        )
    }
    static func max(_ a: Self, _ b: Self) -> Self {
        .init(
            Swift.max(a.x, b.x),
            Swift.max(a.y, b.y),
            Swift.max(a.z, b.z),
            Swift.max(a.w, b.w)
        )
    }
}

extension Vector4 where Scalar: BinaryInteger {
    static func cast<T>(_ v: Vector4<T>) -> Self where T: BinaryFloatingPoint {
        v.map(Scalar.init(_:))
    }
    static func cast<T>(_ v: Vector4<T>) -> Self where T: BinaryInteger {
        v.map(Scalar.init(_:))
    }
}
extension Vector4 where Scalar: FloatingPoint {
    static func cast<Source>(_ v: Vector4<Source>) -> Self where Source: BinaryInteger {
        v.map(Scalar.init(_:))
    }
}
extension Vector4 where Scalar: BinaryFloatingPoint {
    static func cast<Source>(_ v: Vector4<Source>) -> Self where Source: BinaryFloatingPoint {
        v.map(Scalar.init(_:))
    }
}

extension Vector4 where Scalar: FixedWidthInteger {
    static var zero: Vector4<Scalar> {
        .init(.zero)
    }

    static func &<< (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage &<< b.storage)
    }
    static func &<< (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage &<< b)
    }
    static func &<< (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a &<< b.storage)
    }

    static func &<<= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage &<<= b.storage
    }
    static func &<<= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage &<<= b
    }
    static func &>> (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage &>> b.storage)
    }
    static func &>> (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage &>> b)
    }
    static func &>> (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a &>> b.storage)
    }

    static func &>>= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage &>>= b.storage
    }
    static func &>>= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage &>>= b
    }
    static func &+ (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage &+ b.storage)
    }
    static func &+ (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage &+ b)
    }
    static func &+ (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a &+ b.storage)
    }

    static func &+= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage &+= b.storage
    }
    static func &+= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage &+= b
    }
    static func &- (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage &- b.storage)
    }
    static func &- (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage &- b)
    }
    static func &- (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a &- b.storage)
    }

    static func &-= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage &-= b.storage
    }
    static func &-= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage &-= b
    }
    static func &* (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage &* b.storage)
    }
    static func &* (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage &* b)
    }
    static func &* (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a &* b.storage)
    }

    static func &*= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage &*= b.storage
    }
    static func &*= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage &*= b
    }
    static func / (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage / b.storage)
    }
    static func / (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage / b)
    }
    static func / (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a / b.storage)
    }

    static func /= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage /= b.storage
    }
    static func /= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage /= b
    }
    static func % (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage % b.storage)
    }
    static func % (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage % b)
    }
    static func % (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a % b.storage)
    }

    static func %= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage %= b.storage
    }
    static func %= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage %= b
    }

    func roundedUp(exponent: Int) -> Vector4<Scalar> {
        let mask: Scalar = .max &<< exponent
        let truncated: SIMD4<Scalar> = self.storage & mask
        let carry: SIMD4<Scalar> =
        SIMD4<Scalar>.zero.replacing(with: 1 &<< exponent, where: self.storage & ~mask .!= 0)
        return .init(truncated &+ carry)
    }

    var wrappingSum: Scalar {
        self.x &+ self.y &+ self.z &+ self.w
    }
    var wrappingVolume: Scalar {
        self.x &* self.y &* self.z &* self.w
    }

    static func &<> (a: Vector4<Scalar>, b: Vector4<Scalar>) -> Scalar {
        (a &* b).wrappingSum
    }
}

extension Vector4 where Scalar: ExpressibleByIntegerLiteral {
    static var i: Self {
        .init(1, 0, 0, 0)
    }
    static var j: Self {
        .init(0, 1, 0, 0)
    }
    static var k: Self {
        .init(0, 0, 1, 0)
    }
    static var h: Self {
        .init(0, 0, 0, 1)
    }
}

extension Vector4 where Scalar: FloatingPoint {
    static var zero: Vector4<Scalar> {
        .init(.zero)
    }

    prefix static func - (operand: Vector4<Scalar>) -> Vector4<Scalar> {
        .init(-operand.storage)
    }

    static func + (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage + b.storage)
    }
    static func + (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage + b)
    }
    static func + (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a + b.storage)
    }

    static func += (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage += b.storage
    }
    static func += (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage += b
    }
    static func - (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage - b.storage)
    }
    static func - (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage - b)
    }
    static func - (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a - b.storage)
    }

    static func -= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage -= b.storage
    }
    static func -= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage -= b
    }
    static func * (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage * b.storage)
    }
    static func * (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage * b)
    }
    static func * (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a * b.storage)
    }

    static func *= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage *= b.storage
    }
    static func *= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage *= b
    }
    static func / (a: Vector4<Scalar>, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a.storage / b.storage)
    }
    static func / (a: Vector4<Scalar>, b: Scalar)
    -> Vector4<Scalar> {
        .init(a.storage / b)
    }
    static func / (a: Scalar, b: Vector4<Scalar>)
    -> Vector4<Scalar> {
        .init(a / b.storage)
    }

    static func /= (self: inout Vector4<Scalar>, b: Vector4<Scalar>) {
        self.storage /= b.storage
    }
    static func /= (self: inout Vector4<Scalar>, b: Scalar) {
        self.storage /= b
    }

    func addingProduct(_ a: Vector4<Scalar>, _ b: Vector4<Scalar>) -> Vector4<Scalar> {
        .init(self.storage.addingProduct(a.storage, b.storage))
    }
    func addingProduct(_ a: Scalar, _ b: Vector4<Scalar>) -> Vector4<Scalar> {
        .init(self.storage.addingProduct(a, b.storage))
    }
    func addingProduct(_ a: Vector4<Scalar>, _ b: Scalar) -> Vector4<Scalar> {
        .init(self.storage.addingProduct(a.storage, b))
    }
    mutating func addProduct(_ a: Vector4<Scalar>, _ b: Vector4<Scalar>) {
        self.storage.addProduct(a.storage, b.storage)
    }
    mutating func addProduct(_ a: Scalar, _ b: Vector4<Scalar>) {
        self.storage.addProduct(a, b.storage)
    }
    mutating func addProduct(_ a: Vector4<Scalar>, _ b: Scalar) {
        self.storage.addProduct(a.storage, b)
    }

    func squareRoot() -> Vector4<Scalar> {
        .init(self.storage.squareRoot())
    }

    func rounded(_ rule: FloatingPointRoundingRule) -> Vector4<Scalar> {
        .init(self.storage.rounded(rule))
    }
    mutating func round(_ rule: FloatingPointRoundingRule) {
        self.storage.round(rule)
    }

    static func interpolate(_ a: Vector4<Scalar>, _ b: Vector4<Scalar>, by t: Scalar)
    -> Vector4<Scalar> {
        a.addingProduct(a, -t).addingProduct(b, t)
    }


    var sum: Scalar {
        self.x + self.y + self.z + self.w
    }
    var volume: Scalar {
        self.x * self.y * self.z * self.w
    }

    static func <> (a: Vector4<Scalar>, b: Vector4<Scalar>) -> Scalar {
        (a * b).sum
    }

    var length: Scalar {
        (self <> self).squareRoot()
    }

    mutating func normalize() {
        self /= self.length
    }
    func normalized() -> Vector4<Scalar> {
        self / self.length
    }

    static func <  (v: Vector4<Scalar>, r: Scalar) -> Bool {
        v <> v <  r
    }
    static func <= (v: Vector4<Scalar>, r: Scalar) -> Bool {
        v <> v <= r
    }
    static func ~~ (v: Vector4<Scalar>, r: Scalar) -> Bool {
        v <> v == r
    }
    static func !~ (v: Vector4<Scalar>, r: Scalar) -> Bool {
        v <> v != r
    }
    static func >= (v: Vector4<Scalar>, r: Scalar) -> Bool {
        v <> v >= r
    }
    static func >  (v: Vector4<Scalar>, r: Scalar) -> Bool {
        v <> v >  r
    }
}

extension Vector4 where Scalar: FixedWidthInteger {
    static func wrappingAbs(_ v: Self) -> Self {
        .init(v.storage.replacing(with: 0 &- v.storage, where: v.storage .< 0))
    }
}
extension Vector4 where Scalar: FloatingPoint {
    static func abs(_ v: Self) -> Self {
        .init(v.storage.replacing(with: -v.storage, where: v.storage .< 0))
    }
}

extension Vector4: IonEncodable, IonEncodableList where Scalar: IonEncodable {
    @usableFromInline func encode(to ion: inout Ion.ListEncoder) {
        ion[+] = self.x
        ion[+] = self.y
        ion[+] = self.z
        ion[+] = self.w
    }
}

extension Vector4: IonDecodable, IonDecodableList where Scalar: IonDecodable {
    @usableFromInline init(ion: inout Ion.ListDecoder) throws {
        self.init(
            try ion[+].decode(to: Scalar.self),
            try ion[+].decode(to: Scalar.self),
            try ion[+].decode(to: Scalar.self),
            try ion[+].decode(to: Scalar.self)
        )
    }
}
