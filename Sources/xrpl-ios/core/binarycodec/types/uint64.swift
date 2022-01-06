import Foundation

/// Class for serializing and deserializing a 64-bit UInt.
/// See `UInt Fields <https://xrpl.org/serialization.html#uint-fields>`
public class UInt64Type: UIntType {
    
    private static let width = 8 // 64 / 8
    private static let hexRegex = "^[a-fA-F0-9]{1,16}$"
    
    public override init() {
        super.init(bytes: [UInt8](repeating: 0, count: UInt64Type.width))
    }
    
    /// Construct a new UInt64Type type from a `bytes` value.
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }
    
    /// Construct a new UInt64 type from a BinaryParser.
    ///
    /// - Parameter parser: The BinaryParser to construct a UInt64 from.
    /// - Returns: The UInt64Type constructed from parser.
    public override class func fromParser(parser: BinaryParser) throws -> UInt64Type {
        return UInt64Type(bytes: try parser.read(n: width))
    }
    
    /// Construct a new UInt64Type type from a number.
    ///
    /// - Parameter value: The number to construct a UInt64Type from.
    /// - Returns: The UInt64Type constructed from value.
    /// - Throws: `XRPLBinaryCodecException` If a UInt64Type could not be constructed from value.
    public override class func fromValue(value: String) throws -> UInt64Type {
        if let intValue = Int(value) {
            return UInt64Type(bytes: intValue.toByteArray())
        } else if hexRegex.fullMatch(value) {
            var newValue: String
            if value.count >= 16 {
                let index = value.index(value.endIndex, offsetBy: -16)
                newValue = String(value.suffix(from: index))
            } else {
                newValue = String(repeating: "0", count: 16 - value.count) + value
            }
            return UInt64Type(bytes: [UInt8].init(hex: newValue))
        } else {
            throw XRPLBinaryCodeException.types("Cannot construct UInt64 from given value \(value)")
        }
    }
    
    /// Convert a UInt64Type object to JSON (hex).
    ///
    /// - Returns: The JSON representation of the UInt64Type object.
    public override func toJSON() throws -> Any {
        return bytes.toHexString().uppercased()
    }
}
