import Foundation

/// Class for serializing and deserializing an 8-bit UInt.
/// See `UInt Fields <https://xrpl.org/serialization.html#uint-fields>`
public class UInt8Type: UIntType {
    
    private static let width = 1 // 8 / 8
    
    public override init() {
        super.init(bytes: [UInt8](repeating: 0, count: UInt8Type.width))
    }
    
    /// Construct a new UInt8Type type from a `bytes` value.
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }
    
    /// Construct a new UInt8Type type from a BinaryParser.
    ///
    /// - Parameter parser: The parser to construct a UInt8Type from.
    /// - Returns: A new UInt8Type.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> UInt8Type {
        return UInt8Type(bytes: try parser.read(n: width))
    }
    
    /// Construct a new UInt8Type type from a number.
    ///
    /// - Parameter value: The value to construct a UInt8Type from.
    /// - Returns: A new UInt8Type.
    /// - Throws : `XRPLBinaryCodecException`:If a UInt8Type cannot be constructed.
    public override class func fromValue(value: Any) throws -> UInt8Type {
        guard let intValue = value as? Int else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a UInt8Type: expected Int, received \(type(of: value)) type.")
        }
        
        guard intValue > UInt8.min, intValue <= UInt8.max else {
            throw XRPLBinaryCodeException.types("\(intValue) out of range UInt8")
        }
        
        return UInt8Type(bytes: UInt8(intValue).toByteArray())
    }
}
