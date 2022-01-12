import Foundation

/// Codec for serializing and deserializing blob fields. See `Blob Fields <https://xrpl.org/serialization.html#blob-fields>`
public class BlobType: SerializedType {
    
    /// Construct a new BlobType type from a `bytes` value.
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }
    
    /// Defines how to read a Blob from a BinaryParser.
    ///
    /// - Parameters:
    ///     - parser: The parser to construct a Blob from.
    ///     - lengthHint: The number of bytes to consume from the parser.
    /// - Returns: The BlobType constructed from parser.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> BlobType {
        guard let lengthHint = lengthHint else {
            throw XRPLBinaryCodeException.types("Input length hint for initilizing the BlobTyp")
        }
        return BlobType(bytes: try parser.read(n: lengthHint))
    }
    
    /// Create a Blob object from a hex-string.
    ///
    /// - Parameter value: The hex-encoded string to construct a Blob from.
    /// - Returns: The BlobType constructed from value.
    /// - Throws `XRPLBinaryCodecException`: If the Blob can't be constructed from value.
    public override class func fromValue(value: Any) throws -> BlobType {
        guard let stringValue = value as? String else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a Blob: expected str, received \(type(of: value))")
        }
        guard stringValue.isHexString else {
            throw XRPLBinaryCodeException.types("Cannot construct Blob from value given")
        }
        return BlobType(bytes: Array<UInt8>.init(hex: stringValue))
    }
}

extension String {
    var isHexString: Bool {
        filter(\.isHexDigit).count == count
    }
}
