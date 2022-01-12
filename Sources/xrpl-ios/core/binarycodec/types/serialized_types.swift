import Foundation
import CryptoSwift

public protocol SerializedTypeProtocol {
    associatedtype T
    var bytes: [UInt8] { get }
    
    static func fromParser(parser: BinaryParser, lengthHint: Int?) throws -> T
    static func fromValue(value: Any) throws -> T
    static func fromHex(hex: String, lengthHint: Int?) throws -> T
    
    static func getType(by name: String) throws -> T.Type
    
    func toJSON() throws -> Any
    func toHex() -> String
    func toString() -> String
    func length() -> Int
}

extension SerializedTypeProtocol where T == Self {

    public static func fromHex(hex: String, lengthHint: Int? = nil) throws -> T {
        return try fromParser(parser: try BinaryParser(hex: hex), lengthHint: lengthHint)
    }
}

public class SerializedType: SerializedTypeProtocol {

    public var bytes: [UInt8]
    
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    public init() {
        self.bytes = []
    }
    
    /// Write the bytes representation of a SerializedType to a bytearray.
    /// - Parameter bytesink: The bytearray to write self.bytes to.
    public func toByteSink(byteSink: inout [UInt8]) {
        byteSink.append(contentsOf: bytes)
    }
    
    /// Returns the JSON representation of a SerializedType.
    /// If not overridden, returns hex string representation of bytes.
    /// - Returns:The JSON representation of the SerializedType.
    public func toJSON() throws -> Any {
        return toHex()
    }
    
    /// Get the hex representation of a SerializedType's bytes.
    /// - Returns: The hex string representation of the SerializedType's bytes.
    public func toHex() -> String {
        return bytes.toHexString().uppercased()
    }
    
    /// Returns the hex string representation of self.bytes.
    /// - Returns: The hex string representation of self.bytes.
    public func toString() -> String {
        return toHex()
    }
    
    /// Get the length of a SerializedType's bytes.
    public func length() -> Int {
        return bytes.count
    }
    
    public class func fromParser(parser: BinaryParser, lengthHint: Int? = nil) throws -> SerializedType {
        throw XRPLBinaryCodeException.types("Handling in subclass")
    }
    
    public class func fromValue(value: Any) throws -> SerializedType {
        throw XRPLBinaryCodeException.types("Handling in subclass")
    }
    
    public static func getType(by name: String) throws -> SerializedType.Type {
        switch name {
        case "AccoundID":
            return AccountID.self
        case "Amount":
            return AmountType.self
        case "Blob":
            return BlobType.self
        case "Currency":
            return Currency.self
        case "Hash128":
            return Hash128.self
        case "Hash160":
            return Hash160.self
        case "Hash256":
            return Hash256.self
        case "PathSet":
            return PathSetType.self
        case "STArray":
            return SerializedListType.self
        case "STObject":
            return SerializedDictType.self
        case "UInt8":
            return UInt8Type.self
        case "UInt16":
            return UInt16Type.self
        case "UInt32":
            return UInt32Type.self
        case "UInt64":
            return UInt64Type.self
        case "Vector256":
            return Vector256.self
        default:
            throw XRPLBinaryCodeException.types("Not supoprt type with name: \(name)")
        }
    }
}
