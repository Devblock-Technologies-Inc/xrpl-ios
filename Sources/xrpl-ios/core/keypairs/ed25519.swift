import Crypto

public class ED25519Service: CryptoProtocol {
    public func sign(message: [UInt8], privateKey: String) -> [UInt8] {
        return Array<UInt8>()
    }
    
    public func isValidMessage(message: [UInt8], signature: [UInt8], publicKey: [UInt8]) -> Bool {
        return false
    }
    
    public func deriveKeypair(decodedSeed: [UInt8], isValidator: Bool) throws -> KeyPair {
        let rawPrivateKey = Helpers.getSHA512FirstHalf(decodedSeed)
        let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: rawPrivateKey)
        let publicKey = privateKey.publicKey
        
        
        return KeyPair(privateKey: "", publicKey: "")
    }
}

public class Helpers {
    public static func getSHA512FirstHalf(_ data: [UInt8]) -> [UInt8] {
        return Array(SHA512.hash(data: data).prefix(32))
    }
    
//    public func getAccountId(publicKey: [UInt8]) -> [UInt8] {
//        let shaHash = SHA512.hash(data: publicKey)
//
//
//    }
}
