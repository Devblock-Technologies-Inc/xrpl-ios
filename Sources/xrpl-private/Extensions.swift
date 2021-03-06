import Foundation

extension Array {
    
    public init(reserveCapacity: Int) {
        self = Array<Element>()
        self.reserveCapacity(reserveCapacity)
    }
    
    var slice: ArraySlice<Element> {
        return self[self.startIndex ..< self.endIndex]
    }
}

extension UInt64 {
    
    init<T: Collection>(bytes: T) where T.Element == UInt8, T.Index == Int {
        self = UInt64(bytes: bytes, fromIndex: bytes.startIndex)
    }
    
    init<T: Collection>(bytes: T, fromIndex index: T.Index) where T.Element == UInt8, T.Index == Int {
        if bytes.isEmpty {
            self = 0
            return
        }
        
        let count = bytes.count
        
        let val0 = count > 0 ? UInt64(bytes[index.advanced(by: 0)]) << 56 : 0
        let val1 = count > 1 ? UInt64(bytes[index.advanced(by: 1)]) << 48 : 0
        let val2 = count > 2 ? UInt64(bytes[index.advanced(by: 2)]) << 40 : 0
        let val3 = count > 3 ? UInt64(bytes[index.advanced(by: 3)]) << 32 : 0
        let val4 = count > 4 ? UInt64(bytes[index.advanced(by: 4)]) << 24 : 0
        let val5 = count > 5 ? UInt64(bytes[index.advanced(by: 5)]) << 16 : 0
        let val6 = count > 6 ? UInt64(bytes[index.advanced(by: 6)]) << 8 : 0
        let val7 = count > 7 ? UInt64(bytes[index.advanced(by: 7)]) : 0
        
        self = val0 | val1 | val2 | val3 | val4 | val5 | val6 | val7
    }
    
    func rotateLeft(by: UInt8) -> UInt64 {
        return (self << by) | (self >> (64 - by))
    }
}

extension Data {
    
    public func xor(with key: Data) -> Data {
        var result = self
        
        for i in 0..<result.count {
            result[i] ^= key[i % key.count]
        }
        
        return result
    }
    
    public func copy() -> Data {
        guard self.count > 0 else {
            return Data()
        }
        var newData = Data(repeating: 0, count: self.count)
        
        newData.withUnsafeMutableBytes { ptr in
            self.copyBytes(to: ptr.baseAddress!.assumingMemoryBound(to: UInt8.self), count: self.count)
        }
        
        return newData
    }
    
    public var bytes: UnsafePointer<UInt8> {
        return NSData(data: self).bytes.assumingMemoryBound(to: UInt8.self)
    }
    
    public var length: Int {
        return NSData(data: self).length
    }
}
