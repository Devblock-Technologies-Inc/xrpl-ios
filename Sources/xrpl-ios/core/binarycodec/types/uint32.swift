import Foundation

/// Class for serializing and deserializing a 32-bit UInt.
/// See `UInt Fields <https://xrpl.org/serialization.html#uint-fields>`
public class UInt32Type: UIntType {
    
    private static let width = 4 // 32 / 8
    
    public override init() {
        super.init(bytes: [UInt8](repeating: 0, count: UInt32Type.width))
    }
    
    /// Construct a new UInt32 type from a `bytes` value.
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }
    
    /// Construct a new UInt32Type type from a BinaryParser.
    ///
    /// - Parameter parser: A BinaryParser to construct a UInt32 from.
    /// - Returns: The UInt32Type constructed from parser.
    public override class func fromParser(parser: BinaryParser) throws -> UInt32Type {
        return UInt32Type(bytes: try parser.read(n: width))
    }
    
    /// Construct a new UInt32Type type from a number.
    ///
    /// - Parameter value: The number to construct a UInt32Type from.
    /// - Returns: The UInt32Type constructed from value.
    /// - Throws: `XRPLBinaryCodecException` If a UInt32Type could not be constructed from value.
    public override class func fromValue(value: String) throws -> UInt32Type {
        guard let intValue = Int(value) else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a UInt8: expected Int, received \(type(of: value)) type.")
        }
        
        guard intValue > UInt32.min, intValue <= UInt32.max else {
            throw XRPLBinaryCodeException.types("\(intValue) out of range UInt32")
        }
        
        return UInt32Type(bytes: UInt32(intValue).toByteArray())
    }
}
