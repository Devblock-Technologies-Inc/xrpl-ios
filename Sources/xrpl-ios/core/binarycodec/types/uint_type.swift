import Foundation

/// Base class for serializing and deserializing unsigned integers.
/// See `UInt Fields <https://xrpl.org/serialization.html#uint-fields>`
public class UIntType: SerializedType, Hashable {
    
    var value: Int {
        let bigEndianValue = bytes.withUnsafeBufferPointer { $0.baseAddress!.withMemoryRebound(to: Int.self, capacity: 1, { $0 }) }.pointee
        return Int(bigEndian: bigEndianValue)
    }
    
    public static func ==(lsh: UIntType, rhs: UIntType) -> Bool {
        return lsh.value == rhs.value
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
    
    public override func toJSON() throws -> Any {
        return value
    }
}
