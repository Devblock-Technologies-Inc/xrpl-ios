import Foundation

/// Codec for serializing and deserializing a hash field with a width of 160 bits (20 bytes).
///
/// `See Hash Fields <https://xrpl.org/serialization.html#hash-fields>`
public class Hash160: HashType {
    
    internal var width: Int

    internal static let WIDTH: Int = 20

    public override init(bytes: [UInt8]) {
        self.width = Hash160.WIDTH
        super.init(bytes: bytes)
    }

    public override init() {
        let bytesZero = [UInt8](repeating: 0, count: Hash160.WIDTH)
        self.width = Hash160.WIDTH
        super.init(bytes: bytesZero)
    }
    
    public override class func getLength() -> Int {
        return Hash160.WIDTH
    }
}
