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
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> UInt64Type {
        return UInt64Type(bytes: try parser.read(n: width))
    }
    
    /// Construct a new UInt64Type type from a number.
    ///
    /// - Parameter value: The number to construct a UInt64Type from.
    /// - Returns: The UInt64Type constructed from value.
    /// - Throws: `XRPLBinaryCodecException` If a UInt64Type could not be constructed from value.
    public override class func fromValue(value: Any) throws -> UInt64Type {
        if let intValue = value as? Int {
            return UInt64Type(bytes: intValue.toByteArray())
        } else if let stringValue = value as? String, hexRegex.fullMatch(stringValue) {
            var newValue: String
            if stringValue.count >= 16 {
                let index = stringValue.index(stringValue.endIndex, offsetBy: -16)
                newValue = String(stringValue.suffix(from: index))
            } else {
                newValue = String(repeating: "0", count: 16 - stringValue.count) + stringValue
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
