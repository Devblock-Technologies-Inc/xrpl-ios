import Foundation
import CryptoSwift

public protocol HashTypeProtocol {
    static func getLength() -> Int
    var string: String { get }
}

public class HashType: SerializedType, HashTypeProtocol {
    
    public var string: String {
        return bytes.toHexString()
    }
    
    public class func getLength() -> Int {
        return -1
    }
    
    /// Construct a Hash object from a hex string.
    ///
    /// - Parameter value: The value to construct a Hash from.
    /// - Returns: The Hash object constructed from value.
    public override class func fromValue(value: Any) throws -> HashType {
        guard let value = value as? String else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a \(type(of: self)): expected String, received \(type(of: value))")
        }
        return HashType(bytes: Array<UInt8>.init(hex: value))
    }
    
    /// Construct a Hash object from an existing BinaryParser.
    ///
    /// - Parameters:
    ///     - parser: The parser to construct the Hash object from.
    ///     - lengthHint: The number of bytes to consume from the parser.
    /// - Returns: The Hash object constructed from a parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> HashType {
        let numberBytes = lengthHint ?? getLength()
        guard numberBytes > 0 else {
            throw XRPLBinaryCodeException.types("Invalid length")
        }
        return HashType(bytes: try parser.read(n: numberBytes))
    }
}
