import Foundation

public struct Hash128: HashType {
    
    public var bytes: [UInt8]
    internal var width: Int

    public static let WIDTH: Int = 16

    public init(bytes: [UInt8]) {
        self.bytes = bytes
        self.width = Hash128.WIDTH
    }

    public init() {
        let bytesZero = [UInt8](repeating: 0, count: Hash128.WIDTH)
        self.bytes = bytesZero
        self.width = Hash128.WIDTH
    }

    public func getWidth() -> Int {
        return width
    }

    public func fromParser(parser: BinaryParser) -> Hash128 {
        return Hash128()
    }
    
    public func fromParser(parser: BinaryParser, lengthHint: Int) -> Hash128 {
        return Hash128()
    }
    
    public func fromJson(json: [String : Any]) -> Hash128 {
        return Hash128()
    }
}
