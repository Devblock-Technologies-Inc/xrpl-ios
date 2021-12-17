import Foundation

public enum XRPLPrivateError: Error {
    case hash(String)
    case eckey(String)
    case aes(String)
    case ecdh(String)
    case key(String)
}

protocol HashProtocol {
    static func sha256(_ data: Data) throws -> Data
    static func ripemd160(_ data: Data) -> Data
    static func hmacsha512(_ data: Data, key: Data) throws -> Data
    static func hmacsha256(_ data: Data, key: Data, iv: Data, macData: Data) throws -> Data
}

protocol ECKeyProtocol {
    var privateKey: Data { get }
    var publicKey: Data { get }
    
    static func random() throws -> ECKey
}

protocol AESProtocol {
    func encrypt(_ data: Data, withKey: Data, keySize: UInt, iv: Data) -> Data
    func encrypt(_ data: Data, withKey: Data, keySize: UInt) -> Data
}

protocol ECDHProtocol {
    func agree(privateKey: Data, withPublicKey: Data) -> [CUnsignedChar]
}

protocol KeyProtocol {
    static func computePublicKeyFrom(privateKey: Data, isCompress: Bool) throws -> Data
    static func deriveKey(password: Data, salt: Data, iterations: Int, keyLength: Int) -> Data
}

protocol HDKeyProtocol {
    var privateKey: Data { get }
    var publicKey: Data { get }
    var chainCode: Data { get }
    var depth: UInt8 { get }
    var fingerprint: UInt32 { get }
    var childIndex: UInt32 { get }
    
    init(privateKey: Data, publicKey: Data, chainCode: Data, depth: UInt8, fingerprint: UInt32, childIndex: UInt32)
    func derivedAtIndex(_ childIndex: UInt32, hardened: Bool) -> HDKeyProtocol
}
