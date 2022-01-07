import Foundation

/// Codec for serializing and deserializing vectors of Hash256.
public class Vector256: SerializedType {
    
    private static let hashLengthBytes = 32
    
    /// Construct a Vector256.
    public override init(bytes: [UInt8]) {
        super.init(bytes: bytes)
    }
    
    /// Construct a Vector256 from a BinaryParser.
    ///
    /// - Parameters:
    ///     - parser: The parser to construct a Vector256 from.
    ///     - lengthHint: The number of bytes to consume from the parser.
    /// - Returns: A Vector256 object.
    public override class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> Vector256 {
        var byteList = [UInt8]()
        let numberBytes = lengthHint ?? parser.length
        let numberHashes: Int = numberBytes / hashLengthBytes
        for _ in 1...numberHashes {
            try Hash256.fromParser(parser: parser).toByteSink(byteSink: &byteList)
        }
        
        return Vector256(bytes: byteList)
    }
    
    /// Construct a Vector256 from a list of strings.
    ///
    /// - Parameter value: A list of hashes encoded as hex strings.
    /// - Returns: A Vector256 object representing these hashes.
    /// - Throws: `XRPLBinaryCodecException` If the supplied value is of the wrong type.
    public override class func fromValue(value: Any) throws -> Vector256 {
        guard let stringArray = value as? [String] else {
            throw XRPLBinaryCodeException.types("Invalid type to construct a Vector256: expected Array<String>, received \(type(of: value))")
        }
        var byteList = [UInt8]()
        for string in stringArray {
            try Hash256.fromValue(value: string).toByteSink(byteSink: &byteList)
        }
        return Vector256(bytes: byteList)
    }
    
    /// Return a list of hashes encoded as hex strings.
    ///
    /// - Returns: The JSON representation of this Vector256.
    /// - Throws: `XRPLBinaryCodecException` If the number of bytes in the buffer is not a multiple of the hash length.
    public override func toJSON() throws -> Any {
        var hashList = [String]()
        for i in stride(from: 0, to: bytes.count, by: Vector256.hashLengthBytes) {
            let hex = [UInt8](bytes[i ..< i + Vector256.hashLengthBytes]).toHexString()
            hashList.append(hex)
        }
        return hashList
    }
}
