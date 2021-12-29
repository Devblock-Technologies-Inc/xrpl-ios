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
    public override class func fromValue(value: String) throws -> HashType {
        return HashType(bytes: Array<UInt8>.init(hex: value))
    }
    
    public override class func fromParser(parser: BinaryParser) throws -> HashType {
        guard HashType.getLength() > 0 else {
            throw XRPLBinaryCodeException.types("Invalid length")
        }
        return HashType(bytes: try parser.read(n: HashType.getLength()))
    }
    
    public override class func fromParser(parser: BinaryParser, lengthHint: Int) throws -> HashType {
        guard lengthHint > 0 else {
            throw XRPLBinaryCodeException.types("Invalid lengthHint")
        }
        return HashType(bytes: try parser.read(n: lengthHint))
    }
}
