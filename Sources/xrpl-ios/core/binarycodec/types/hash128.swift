import Foundation

/// Codec for serializing and deserializing a hash field with a width of 128 bits (16 bytes).
///
/// `See Hash Fields <https://xrpl.org/serialization.html#hash-fields>`
public class Hash128: HashType {

    internal static let width: Int = 16

    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }

    public override init() {
        let bytesZero = [UInt8](repeating: 0, count: Hash128.width)
        super.init(bytes: bytesZero)
    }
    
    public override class func getLength() -> Int {
        return Hash128.width
    }
    
    /// Construct a Hash128 object from a hex string.
    ///
    /// - Parameter value: The value to construct a Hash from.
    /// - Returns: The Hash128 object constructed from value.
    public override class func fromValue(value: Any) throws -> Hash128 {
        guard let value = value as? String else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a \(type(of: self)): expected String, received \(type(of: value))")
        }
        return Hash128(bytes: Array<UInt8>.init(hex: value))
    }
    
    /// Construct a Hash128 object from an existing BinaryParser.
    ///
    /// - Parameters:
    ///     - parser: The parser to construct the Hash object from.
    ///     - lengthHint: The number of bytes to consume from the parser.
    /// - Returns: The Hash128 object constructed from a parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> Hash128 {
        let numberBytes = lengthHint ?? getLength()
        guard numberBytes == Hash128.width else {
            throw XRPLBinaryCodeException.types("Invalid length")
        }
        return Hash128(bytes: try parser.read(n: numberBytes))
    }
}
