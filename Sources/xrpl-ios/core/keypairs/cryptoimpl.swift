import Foundation
import Crypto
import xrpl_private

/// Protocol for cryptographic algorithms in the XRP Ledger. The classes for all cryptographic algorithms are derived from this protocol.
internal protocol CryptoProtocol {
    static func deriveKeypair(decodedSeed: [UInt8], isValidator: Bool) throws -> KeyPair
    static func sign(message: [UInt8], privateKey: String) throws -> [UInt8]
    static func isValidMessage(message: [UInt8], signature: [UInt8], publicKey: String) throws -> Bool
}

extension CryptoProtocol {
    
    /// Compute the RIPEMD160 of the SHA256 of the given public key, which can be encoded to an XRPL address.
    /// - Parameter publicKey: The public key that should be hashed.
    /// - Returns: An bytes containing the non-encoded XRPL address derived from the public key.
    private func computePublicKeyHash(publicKey: [UInt8]) -> [UInt8] {
        let sha512 = publicKey.sha512()
        
        let ripemd160 = xrpl_private.Hash.ripemd160(Data(sha512))
        
        return [UInt8](ripemd160)
    }
}

public enum XRPLKeyPairException: XRPLException {
    case secRandom(String)
    case deriveKey(String)
}

extension XRPLKeyPairException: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .secRandom(let message):
            return NSLocalizedString("KeyPairs Service - \(message)", comment: "")
        case .deriveKey(let message):
            return NSLocalizedString("KeyPairs Service - \(message)", comment: "")
        }
    }
}


public class KeyPairHelpers {
    /// Returns the first 32 bytes of SHA-512 hash of message.
    ///
    /// - Parameter data: Bytes input to hash.
    /// - Returns: The first 32 bytes of SHA-512 hash of data.
    public static func getSHA512FirstHalf(_ data: [UInt8]) -> [UInt8] {
        return Array(SHA512.hash(data: data).prefix(32))
    }
    
    /// Returns the account ID for a given public key.
    ///
    /// - Parameter publicKey: Unencoded public key.
    /// - Returns: The account ID for the given public key.
    ///
    /// See https://xrpl.org/cryptographic-keys.html#account-id-and-address to learn about the relationship between keys and account IDs.
    public static func getAccountId(publicKey: [UInt8]) -> [UInt8] {
        let sha256Hash = xrpl_private.Hash.sha256(Data(publicKey))
        let ripemd160 = xrpl_private.Hash.ripemd160(sha256Hash)
        
        return [UInt8](ripemd160)
    }
}
