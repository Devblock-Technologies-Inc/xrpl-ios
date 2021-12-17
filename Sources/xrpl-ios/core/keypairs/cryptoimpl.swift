import Foundation
import CryptoSwift
import xrpl_private

/// Protocol for cryptographic algorithms in the XRP Ledger. The classes for all cryptographic algorithms are derived from this protocol.
public protocol CryptoProtocol {
    func deriveKeypair(decodedSeed: [UInt8], isValidator: Bool) throws -> KeyPair
    func sign(message: [UInt8], privateKey: String) -> [UInt8]
    func isValidMessage(message: [UInt8], signature: [UInt8], publicKey: [UInt8]) -> Bool
}

extension CryptoProtocol {
    
    public func deriveAddress(publicKey: String) -> String {
        
        return ""
    }
    
    /// Compute the RIPEMD160 of the SHA256 of the given public key, which can be encoded to an XRPL address.
    /// - Parameter publicKey: The public key that should be hashed.
    /// - Returns: An bytes containing the non-encoded XRPL address derived from the public key.
    private func computePublicKeyHash(publicKey: [UInt8]) -> [UInt8] {
        let sha512 = publicKey.sha512()
        
        let ripemd160 = xrpl_private.Hash.ripemd160(Data(sha512))
        
        return [UInt8](ripemd160)
    }
}
