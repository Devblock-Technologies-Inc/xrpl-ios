import Foundation

public protocol SerializedType {
    associatedtype T
    var bytes: [UInt8] { get }
    
    func fromParser(parser: BinaryParser) -> T
    func fromParser(parser: BinaryParser, lengthHint: Int) -> T
    func fromJson(json: [String: Any]) -> T
    func fromHex(hex: String) -> T
    func fromHex(hex: String, lengthHint: Int) -> T
}

extension SerializedType {
    public func fromHex(hex: String) -> T {
        return fromParser(parser: BinaryParser(hex: hex))
    }
    
    public func fromHex(hex: String, lengthHint: Int) -> T {
        return fromParser(parser: BinaryParser(hex: hex), lengthHint: lengthHint)
    }
    
    public func toByteSink(byteSink: inout [UInt8]) {
        byteSink.append(contentsOf: bytes)
    }
}
