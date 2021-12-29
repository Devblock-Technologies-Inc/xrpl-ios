import Foundation

/// Codec for serializing and deserializing a hash field with a width of 256 bits (32 bytes).
///
/// `See Hash Fields <https://xrpl.org/serialization.html#hash-fields>`
public class Hash256: HashType {
    
    internal var width: Int

    internal static let WIDTH: Int = 32

    public override init(bytes: [UInt8]) {
        self.width = Hash256.WIDTH
        super.init(bytes: bytes)
    }

    public override init() {
        let bytesZero = [UInt8](repeating: 0, count: Hash256.WIDTH)
        self.width = Hash256.WIDTH
        super.init(bytes: bytesZero)
    }
    
    public override class func getLength() -> Int {
        return Hash256.WIDTH
    }
}
