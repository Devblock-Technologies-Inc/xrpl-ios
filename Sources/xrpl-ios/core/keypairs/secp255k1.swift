import Foundation

internal struct SECP255K1Service: CryptoProtocol {
    
    internal static func deriveKeypair(decodedSeed: [UInt8], isValidator: Bool) throws -> KeyPair {
        return KeyPair(privateKey: "", publicKey: "")
    }
    
    internal static func sign(message: [UInt8], privateKey: String) throws -> [UInt8] {
        return [UInt8]()
    }
    
    internal static func isValidMessage(message: [UInt8], signature: [UInt8], publicKey: String) throws -> Bool {
        return false
    }
}
