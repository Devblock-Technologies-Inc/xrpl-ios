import Foundation

/// Model object for field info metadata from the "fields" section of definitions.json.
public struct FieldInfo: Codable {
    
    public let nth: Int
    public let isVLEncoded: Bool
    public let isSerialized: Bool
    public let isSigningField: Bool
    public let type: String
}
