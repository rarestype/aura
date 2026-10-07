import Aura

extension AuraArchive {
    subscript(name: String) -> Body? {
        self.bodies.first { $0.name == name }
    }
}
