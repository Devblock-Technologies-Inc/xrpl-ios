import Foundation
import CommonCrypto
import BigInt

enum Base58 {

    /// Includes a 4-byte checksum so that the probability of generating a valid address from random characters is approximately 1 in 2**32
    private static let checksumLength = 4
    private static let zero = BigUInt(0)

    /// Encode the given bytes into a Base58Check encoded string.
    /// - Parameter bytes: The bytes to encode.
    /// - Parameter alphabet: The dictionary used for XRPL base58 encodings
    /// - Returns: A base58check encoded string representing the given bytes, or empty if encoding failed.
    public static func encodeCheck(_ bytes: [UInt8], alphabet: [UInt8]) -> String {
        let checksum = calculateChecksum(bytes)
        let checksummedBytes = bytes + checksum
        return Base58.encode(checksummedBytes, alphabet: alphabet)
    }
    
    /// Decode the given Base58Check encoded string to bytes.
    /// - Parameters:
    ///     - input: A base58check encoded input string to decode.
    ///     - alphabet: The dictionary used for XRPL base58 encodings
    ///     - prefix: The prefix prepended to the bytestring.
    /// - Returns: Bytes representing the decoded input, or nil if decoding failed.
    /// - Throws: `XRPLAddressCodecException`: if decoding failed or the checksum is incorrect
    public static func decodeCheck(_ input: String, alphabet: [UInt8], prefix: [UInt8] = []) throws -> [UInt8] {
        guard var decodedChecksummedBytes = Base58.decode(input, alphabet: alphabet) else {
            throw XRPLAddressCodecException.decodingFailed("XRPL base58 encodings")
        }
        
        decodedChecksummedBytes = prefix + decodedChecksummedBytes
        
        let decodedChecksum = decodedChecksummedBytes.suffix(checksumLength)
        let decodedBytes = decodedChecksummedBytes.prefix(upTo: decodedChecksummedBytes.count - checksumLength)
        let calculatedChecksum = calculateChecksum([UInt8](decodedBytes))
        
        guard decodedChecksum.elementsEqual(calculatedChecksum, by: { $0 == $1 }) else {
            throw XRPLAddressCodecException.decodingFailed("Checksum incorrect")
        }
        
        return Array(decodedBytes)
    }
    
    /// Encode the given bytes to a Base58 encoded string.
    /// - Parameter bytes: The bytes to encode
    /// - Parameter alphabet: The dictionary used for XRPL base58 encodings
    /// - Returns: A base58 encoded string representing the given bytes, or empty if encoding failed
    public static func encode(_ bytes: [UInt8], alphabet: [UInt8]) -> String {
        var answer: [UInt8] = []
        var integerBytes = BigUInt(Data(bytes))
        let radix = BigUInt(alphabet.count)

        while integerBytes > 0 {
            let (quotient, remember) = integerBytes.quotientAndRemainder(dividingBy: radix)
            answer.insert(alphabet[Int(remember)], at: 0)
            integerBytes = quotient
        }

        let prefix = Array(bytes.prefix { $0 == 0 }).map { _ in alphabet[0] }
        answer.insert(contentsOf: prefix, at: 0)

        return String(bytes: answer, encoding: .utf8) ?? ""
    }
    
    /// Decode the given base58 encoded string to bytes.
    /// - Parameter input: The base58 encoded input string to decode.
    /// - Parameter alphabet: The dictionary used for XRPL base58 encodings
    /// - Returns: Bytes representing the decoded input, or nil if decoding fail.
    public static func decode(_ input: String, alphabet: [UInt8]) -> [UInt8]? {
        var answer = zero
        var index = BigUInt(1)
        let byteString = input.bytes
        let radix = BigUInt(alphabet.count)
        
        for char in byteString.reversed() {
            guard let alphabetIndex = alphabet.firstIndex(of: char) else { return nil }
            
            answer += index * BigUInt(alphabetIndex)
            index *= radix
        }
        
        let bytes = answer.serialize()
        return [UInt8](Array(bytes.prefix { $0 == alphabet[0] }) + bytes)
    }

    /// Calculate a checksum for a given input by hashing twice and then taking the first four bytes.
    /// - Parameter input: The input bytes.
    /// - Returns: A byte array representing the checksum of the input bytes.
    private static func calculateChecksum(_ input: [UInt8]) -> [UInt8] {
        let hashedData = sha256(input)
        let doubleHashedData = sha256(hashedData)
        let doubleHasedArray = Array(doubleHashedData)

        return Array(doubleHasedArray.prefix(checksumLength))
    }

    /// Create a sha256 hash of the given data.
    /// - Parameter data: Input data to hash.
    /// - Returns: A sha256 hash of the input data.
    private static func sha256(_ data: [UInt8]) -> [UInt8] {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return [] }
        CC_SHA256(
            (Data(data) as NSData).bytes,
            CC_LONG(data.count),
            res.mutableBytes.assumingMemoryBound(to: UInt8.self)
        )

        return [UInt8](res as Data)
    }
}
