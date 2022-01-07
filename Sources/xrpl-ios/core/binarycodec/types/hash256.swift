import Foundation

/// Codec for serializing and deserializing a hash field with a width of 256 bits (32 bytes).
///
/// `See Hash Fields <https://xrpl.org/serialization.html#hash-fields>`
public class Hash256: HashType {
    
    internal static let width: Int = 32

    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }

    public override init() {
        let bytesZero = [UInt8](repeating: 0, count: Hash256.width)
        super.init(bytes: bytesZero)
    }
    
    public override class func getLength() -> Int {
        return Hash256.width
    }
    
    /// Construct a Hash256 object from a hex string.
    ///
    /// - Parameter value: The value to construct a Hash from.
    /// - Returns: The Hash256 object constructed from value.
    public override class func fromValue(value: Any) throws -> Hash256 {
        guard let value = value as? String else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a \(type(of: self)): expected String, received \(type(of: value))")
        }
        return Hash256(bytes: Array<UInt8>.init(hex: value))
    }
    
    /// Construct a Hash256 object from an existing BinaryParser.
    ///
    /// - Parameters:
    ///     - parser: The parser to construct the Hash object from.
    ///     - lengthHint: The number of bytes to consume from the parser.
    /// - Returns: The Hash256 object constructed from a parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> Hash256 {
        let numberBytes = lengthHint ?? getLength()
        guard numberBytes == Hash256.width else {
            throw XRPLBinaryCodeException.types("Invalid length")
        }
        return Hash256(bytes: try parser.read(n: numberBytes))
    }
}
