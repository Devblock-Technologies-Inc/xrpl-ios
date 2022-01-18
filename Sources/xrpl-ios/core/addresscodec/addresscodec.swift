import Foundation

/// This class handles everething related to X-Address.
///
/// - Class `AddressCodec`
public class AddressCodec: Codec {
    
    /// Max Unsigned Integer 32 bits: 4294967295
    static let max32BitsUnsignedInt = UInt32.max
    
    /// 5, 68
    private let prefixByteMain: [UInt8] = [0x05, 0x44]
    
    /// 4, 147
    private let prefixByteTest: [UInt8] = [0x04, 0x93]
    
    /**
     # To better understand the cryptographic details, visit
     - `https://github.com/xrp-community/standards-drafts/issues/6`

     # General format of an X-Address:
     - [← 2 byte prefix →|← 160 bits of account ID →|← 8 bits of flags →|← 64 bits of tag →]
     */
    
    /**
     Returns the X-Address representation of the data.
     - Parameters:
        - classicAddress: The base58 encoding of the classic address.
        - tag: The destination tag.
        - isTestNetwork: Whether it is the test network or the main network.
     - Returns: The X-Address representation of the data.
     - Throws: `XRPLAddressCodecException`: If the classic address does not have enough bytes
                 or the tag is invalid.
     */
    public func classicAddressToXAddress(classicAddress: String, tag: Int = 0, isTestNetwork: Bool) throws -> String {
        let classicAddressBytes = try decodeClassicAddress(classicAddress)
        
        guard classicAddressBytes.count == 20 else {
            throw XRPLAddressCodecException.accountLength
        }
        
        guard tag <= AddressCodec.max32BitsUnsignedInt else {
            throw XRPLAddressCodecException.invalidTag
        }
        
        var byteString = isTestNetwork ? prefixByteTest : prefixByteMain
        byteString.append(contentsOf: classicAddressBytes)
        
        let flag: UInt8 = tag == 0 ? 0 : 1
        
        let encodedTag: [UInt8] = [
            flag,
            UInt8(_truncatingBits: UInt(tag) & 0xFF),
            UInt8(_truncatingBits: UInt(tag) >> 8 & 0xFF),
            UInt8(_truncatingBits: UInt(tag) >> 16 & 0xFF),
            UInt8(_truncatingBits: UInt(tag) >> 24 & 0xFF),
            0, 0, 0, 0
        ]
        
        byteString.append(contentsOf: encodedTag)
        
        return XBase58Check.encode(Data(byteString))
    }
    
    /**
     Returns a tuple containing the classic address, tag, and whether the address is on a test network for an X-Address.
     - Parameter xAddress: base58-encoded X-Address.
     - Returns: A tuple containing: classicAddress: the base58 classic address, tag: the destination tag, isTestNetwork: whether the address is on the test network (or main)
     - Throws: `XRPLAddressCodecException` if decoded failure or the X-Address is invalid length
     */
    public func xAddresToClassicAddress(xAddress: String)
    throws -> (classicAddress: String, tag: Int, isTestNetwork: Bool) { // swiftlint:disable:this large_tuple
        let decoded = try XBase58Check.decode(xAddress)
        
        guard decoded.count == 31 else {
            throw XRPLAddressCodecException.decodingFailed("Invalid length X-Address")
        }
        
        let classicAddressBytes = Array(decoded[2..<22])
        
        let classicAddress = try encodeClassicAddress(classicAddressBytes)
        
        let tag = try getTag(from: decoded)
        let isTestNetwork = try isTestAddress(decoded: decoded)
        
        return (classicAddress, tag, isTestNetwork)
    }
    
    /**
     Returns whether `xaddress` is a valid X-Address.
     - Parameter xAddress: The X-Address to check validity.
     - Returns: Whether `xaddress` is a valid X-Address.
     */
    public func isValidXAddress(xAddress: String) -> Bool {
        do {
            _ = try xAddresToClassicAddress(xAddress: xAddress)
            return true
        } catch {
            return false
        }
    }
    
    /**
     Returns whether a decoded X-Address is a test address.
     - Parameter decoded: base58 decoded X-Address
     - Returns: Whether a decoded X-Address is a test address.
     - Throws: `XRPLAddressCodecException`: If the prefix is invalid.
     */
    private func isTestAddress(decoded: [UInt8]) throws -> Bool {
        guard decoded.count == 31 else {
            throw XRPLAddressCodecException.decodingFailed("Invalid length X-Address")
        }
        
        let prefix = Array(decoded[0..<2])
        if  prefix == prefixByteTest {
            return true
        } else if prefix == prefixByteMain {
            return false
        } else {
            throw XRPLAddressCodecException.decodingFailed("Invalid X-Address: Bad Prefix")
        }
    }
    
    /**
     Returns the destination tag extracted from the suffix of the X-Address.
     - Parameter decoded: base58 decoded X-Address
     - Returns: the destination tag extracted from the suffix of the X-Address.
     - Throws: `XRPLAddressCodecException`: if the flag is invalid
     */
    private func getTag(from decoded: [UInt8]) throws -> Int {
        guard decoded.count == 31 else {
            throw XRPLAddressCodecException.decodingFailed("Invalid length X-Address")
        }
        
        let flag = decoded[22]
        
        guard flag <= 2 else {
            throw XRPLAddressCodecException.decodingFailed("Unsupported X-Address: 64-bit tags are not supported")
        }
        
        if flag == 1 {
            // Little-endian to big-endian
            let tagBytes = Array(decoded[23...26])
            
            // swiftlint:disable force_unwrapping
            let tagLittleEndian = tagBytes.withUnsafeBufferPointer { $0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 } }.pointee
            // swiftlint:enable force_unwrapping
            
            return Int(UInt32(littleEndian: tagLittleEndian))
        } else if flag == 0 {
            let hexZeroBytes = String(repeating: "0", count: 16).bytesFromHexString
            let decodedTagBytes = Array(decoded[23...31])
            
            if hexZeroBytes != decodedTagBytes {
                throw XRPLAddressCodecException.decodingFailed("Tag bytes in X-Address must be 0 if the address has no tag.")
            }
            return 0
        } else {
            throw XRPLAddressCodecException.decodingFailed("Flag must be 0 to indicate no tag.")
        }
    }
}
