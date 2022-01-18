import Foundation
import xrpl_private

internal protocol XEncoding {
    static var baseAlphabets: String { get }
    static var zeroAlphabet: Character { get }
    static var base: Int { get }

    // log(256) / log(base), rounded up
    static func sizeFromByte(size: Int) -> Int
    // log(base) / log(256), rounded up
    static func sizeFromBase(size: Int) -> Int

    // Public
    static func encode(_ bytes: Data) -> String
    static func decode(_ string: String) -> Data?
}

// The Base encoding used is home made, and has some differences. Especially,
// leading zeros are kept as single zeros when conversion happens.
extension XEncoding {
    static func convertBytesToBase(_ bytes: Data) -> [UInt8] {
        var length = 0
        let size = sizeFromByte(size: bytes.count)
        var encodedBytes: [UInt8] = Array(repeating: 0, count: size)

        for b in bytes {
            var carry = Int(b)
            var i = 0
            for j in (0...encodedBytes.count - 1).reversed() where carry != 0 || i < length {
                carry += 256 * Int(encodedBytes[j])
                encodedBytes[j] = UInt8(carry % base)
                carry /= base
                i += 1
            }

            assert(carry == 0)

            length = i
        }

        var zerosToRemove = 0
        for b in encodedBytes {
            if b != 0 { break }
            zerosToRemove += 1
        }

        encodedBytes.removeFirst(zerosToRemove)
        return encodedBytes
    }

    static func encode(_ bytes: Data) -> String {
        var bytes = bytes
        var zerosCount = 0

        for b in bytes {
            if b != 0 { break }
            zerosCount += 1
        }

        bytes.removeFirst(zerosCount)

        let encodedBytes = convertBytesToBase(bytes)

        var str = ""
        while 0 < zerosCount {
            str += String(zeroAlphabet)
            zerosCount -= 1
        }

        for b in encodedBytes {
            let index = String.Index(utf16Offset: Int(b), in: baseAlphabets)
            str += String(baseAlphabets[index])
        }

        return str
    }

    static func decode(_ string: String) -> Data? {
        guard !string.isEmpty else { return nil }

        var zerosCount = 0
        var length = 0
        for c in string {
            if c != zeroAlphabet { break }
            zerosCount += 1
        }
        let size = sizeFromBase(size: string.lengthOfBytes(using: .utf8) - zerosCount)
        var decodedBytes: [UInt8] = Array(repeating: 0, count: size)
        for c in string {
            guard let baseIndex: Int = baseAlphabets.firstIndex(of: c)?.utf16Offset(in: baseAlphabets) else { return nil }
            var carry = baseIndex
            var i = 0
            for j in (0...decodedBytes.count - 1).reversed() where carry != 0 || i < length {
                carry += base * Int(decodedBytes[j])
                decodedBytes[j] = UInt8(carry % 256)
                carry /= 256
                i += 1
            }

            assert(carry == 0)
            length = i
        }

        // skip leading zeros
        var zerosToRemove = 0

        for b in decodedBytes {
            if b != 0 { break }
            zerosToRemove += 1
        }
        decodedBytes.removeFirst(zerosToRemove)

        return Data(repeating: 0, count: zerosCount) + Data(decodedBytes)
    }
}

private struct _XBase58: XEncoding {
    static let baseAlphabets = "rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz"
    static var zeroAlphabet: Character = "r"
    static var base: Int = 58

    static func sizeFromByte(size: Int) -> Int {
        return size * 138 / 100 + 1
    }
    static func sizeFromBase(size: Int) -> Int {
        return size * 733 / 1000 + 1
    }
}

public struct XBase58 {
    public static func encode(_ bytes: Data) -> String {
        return _XBase58.encode(bytes)
    }
    public static func decode(_ string: String) -> Data? {
        return _XBase58.decode(string)
    }
}

public struct XBase58Check {
    /// Encodes the data to XBase58Check encoded string
    ///
    /// Puts checksum bytes to the original data and then, encode the combined
    /// data to XBase58 string.
    /// ```
    /// let address = XBase58Check.encode([versionByte] + pubkeyHash)
    /// ```
    public static func encode(_ payload: Data) -> String {
        let checksum: Data = xrpl_private.Hash.sha256sha256(payload).prefix(4)
        return XBase58.encode(payload + checksum)
    }

    /// Decode the XBase58 encoded String value to original payload
    ///
    /// First validate if checksum bytes are the first 4 bytes of the sha256(sha256(payload)).
    /// If it's valid, returns the original payload.
    /// ```
    /// let payload = try XBase58Check.decode(base58checkText)
    /// ```
    public static func decode(_ string: String) throws -> [UInt8] {
        guard let raw = XBase58.decode(string) else {
            throw XRPLAddressCodecException.decodingFailed("XRPL base58 encodings")
        }
        let checksum = raw.suffix(4)
        let payload = raw.dropLast(4)
        let checksumConfirm = xrpl_private.Hash.sha256sha256(payload).prefix(4)
        guard checksum == checksumConfirm else {
            throw XRPLAddressCodecException.decodingFailed("Checksum incorrect")
        }

        return [UInt8](payload)
    }
}
