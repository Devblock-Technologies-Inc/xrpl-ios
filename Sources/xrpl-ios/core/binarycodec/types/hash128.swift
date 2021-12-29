import Foundation

/// Codec for serializing and deserializing a hash field with a width of 128 bits (16 bytes).
///
/// `See Hash Fields <https://xrpl.org/serialization.html#hash-fields>`
public class Hash128: HashType {
    
    internal var width: Int

    internal static let WIDTH: Int = 16

    public override init(bytes: [UInt8]) {
        self.width = Hash128.WIDTH
        super.init(bytes: bytes)
    }

    public override init() {
        let bytesZero = [UInt8](repeating: 0, count: Hash128.WIDTH)
        self.width = Hash128.WIDTH
        super.init(bytes: bytesZero)
    }
    
    public override class func getLength() -> Int {
        return Hash128.WIDTH
    }
}
