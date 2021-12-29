import Foundation
import CryptoSwift

public protocol SerializedTypeProtocol {
    associatedtype T
    var bytes: [UInt8] { get }
    
    static func fromParser(parser: BinaryParser) throws -> T
    static func fromParser(parser: BinaryParser, lengthHint: Int) throws -> T
    static func fromJson(json: [String: Any]) throws -> T
    static func fromValue(value: String) throws -> T
    static func fromHex(hex: String) throws -> T
    static func fromHex(hex: String, lengthHint: Int) throws -> T
    
    static func getType(by name: String) -> T.Type
    
    func toJSON() throws -> Any
    func toHex() -> String
    func toString() -> String
    func length() -> Int
}

extension SerializedTypeProtocol where T == Self {
    public static func fromHex(hex: String) throws -> T {
        return try fromParser(parser: try BinaryParser(hex: hex))
    }
    
    public static func fromHex(hex: String, lengthHint: Int) throws -> T {
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
    
    public class func fromParser(parser: BinaryParser) throws -> SerializedType {
        throw XRPLBinaryCodeException.types("Handling in subclass")
    }
    
    public class func fromParser(parser: BinaryParser, lengthHint: Int) throws -> SerializedType {
        throw XRPLBinaryCodeException.types("Handling in subclass")
    }
    
    public class func fromJson(json: [String : Any]) throws -> SerializedType {
        throw XRPLBinaryCodeException.types("Handling in subclass")
    }
    
    public class func fromValue(value: String) throws -> SerializedType {
        throw XRPLBinaryCodeException.types("Handling in subclass")
    }
    
    public static func getType(by name: String) -> SerializedType.Type {
        switch name {
        case "Hash128":
            return Hash128.self
        default:
            fatalError("Invalid Type: \(name)")
        }
    }
}
