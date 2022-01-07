import Foundation

/// Class for serializing and deserializing a 16-bit UInt.
/// See `UInt Fields <https://xrpl.org/serialization.html#uint-fields>`
public class UInt16Type: UIntType {
    
    private static let width = 2 // 16 / 8
    
    public override init() {
        super.init(bytes: [UInt8](repeating: 0, count: UInt16Type.width))
    }
    
    /// Construct a new UInt16Type type from a `bytes` value.
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }
    
    /// Construct a new UInt16Type type from a BinaryParser.
    ///
    /// - Parameter parser: The BinaryParser to construct a UInt16Type from.
    /// - Returns: The UInt16Type constructed from parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> UInt16Type {
        return UInt16Type(bytes: try parser.read(n: width))
    }
    
    /// Construct a new UInt16Type type from a number.
    ///
    /// - Parameter value: The value to construct a UInt16Type from.
    /// - Returns: The UInt16Type constructed from value.
    /// - Throws: `XRPLBinaryCodecException` If a UInt16Type can't be constructed from value.
    public override class func fromValue(value: Any) throws -> UInt16Type {
        guard let intValue = value as? Int else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a UInt8: expected Int, received \(type(of: value)) type.")
        }
        
        guard intValue > UInt16.min, intValue <= UInt16.max else {
            throw XRPLBinaryCodeException.types("\(intValue) out of range UInt16")
        }
        
        return UInt16Type(bytes: UInt16(intValue).toByteArray())
    }
}
