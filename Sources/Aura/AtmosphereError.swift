public enum AtmosphereError: Error, Sendable {
    case invalidDetail(Int)
    case invalidConfigFile(String)
}
