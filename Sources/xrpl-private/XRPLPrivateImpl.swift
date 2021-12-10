import Foundation
import OpenSSL

extension XRPLPrivateError: LocalizedError {
    var localizedDescription: String? {
        switch self {
        case .hash(let description):
            return NSLocalizedString("HASH ERROR: \(description)", comment: "")
        case .eckey(let description):
            return NSLocalizedString("ECKey ERROR: \(description)", comment: "")
        case .aes(let description):
            return NSLocalizedString("AES ERROR: \(description)", comment: "")
        case .ecdh(let description):
            return NSLocalizedString("ECDH ERROR: \(description)", comment: "")
        case .key(let description):
            return NSLocalizedString("HDKey ERROR: \(description)", comment: "")
        }
    }
}

public class Hash: HashProtocol {
    
    public static func sha256(_ data: Data) throws -> Data {
        guard let result = NSMutableData(length: Int(SHA256_DIGEST_LENGTH)) else {
            throw XRPLPrivateError.hash("Could not init NSMutableData with SHA256_DIGEST_LENGTH length")
        }
        
        SHA256(data.bytes, data.length, result.mutableBytes.assumingMemoryBound(to: UInt8.self))
        
        return result as Data
    }
    
    public static func sha256sha256(_ data: Data) throws -> Data {
        return try sha256(try sha256(data))
    }
    
    public static func ripemd160(_ data: Data) throws -> Data {
        guard let result = NSMutableData(length: Int(RIPEMD160_DIGEST_LENGTH)) else {
            throw XRPLPrivateError.hash("Could not init NSMutableData with RIPEMD160_DIGEST_LENGTH length")
        }
        
        RIPEMD160(data.bytes, data.length, result.mutableBytes.assumingMemoryBound(to: UInt8.self))
        
        return result as Data
    }
    
    public static func hmacsha512(_ data: Data, key: Data) throws -> Data {
        var length = UInt32(SHA512_DIGEST_LENGTH)
        guard let result = NSMutableData(length: Int(length)) else {
            throw XRPLPrivateError.hash("Could not init NSMutableData with SHA512_DIGEST_LENGTH length")
        }
        
        HMAC(EVP_sha512(), key.bytes, Int32(truncatingIfNeeded: key.length), data.bytes, data.length, result.mutableBytes.assumingMemoryBound(to: UInt8.self), &length)
        
        return result as Data
    }
    
    public static func hmacsha256(_ data: Data, key: Data, iv: Data, macData: Data) throws -> Data {
        let context = HMAC_CTX_new()
        HMAC_CTX_reset(context)
        HMAC_Init_ex(context, key.bytes, Int32(truncatingIfNeeded: key.length), EVP_sha256(), nil)
        HMAC_Update(context, iv.bytes, iv.length)
        HMAC_Update(context, data.bytes, data.length)
        HMAC_Update(context, macData.bytes, macData.length)
        
        var length = UInt32(SHA256_DIGEST_LENGTH)
        guard let result = NSMutableData(length: Int(length)) else {
            throw XRPLPrivateError.hash("Could not init NSMutableData with SHA256_DIGEST_LENGTH length")
        }
        HMAC_Final(context, result.mutableBytes.assumingMemoryBound(to: UInt8.self), &length)
        HMAC_CTX_free(context)
        
        return result as Data
    }
}

public class ECKey: ECKeyProtocol {
    
    var privateKey: Data
    var publicKey: Data
    
    public init(privateKey: Data, publicKey: Data) {
        self.privateKey = privateKey
        self.publicKey = publicKey
    }
    
    public static func random() throws -> ECKey {
        let contex = BN_CTX_new()
        let eckey = EC_KEY_new_by_curve_name(NID_secp256k1)
        EC_KEY_generate_key(eckey)
        let group = EC_KEY_get0_group(eckey)
        
        let privateKey = EC_KEY_get0_private_key(eckey)
        guard let privateBytes = NSMutableData(length: 32) else {
            throw XRPLPrivateError.eckey("Could not create ECPrivateKey")
        }
        BN_bn2bin(privateKey, privateBytes.mutableBytes.assumingMemoryBound(to: UInt8.self))
        
        let publicPoint = EC_KEY_get0_public_key(eckey)
        guard let publicBytes = NSMutableData(length: 65) else {
            throw XRPLPrivateError.eckey("Could not create ECPublicKey")
        }
        let publicKey = BN_new()
        EC_POINT_point2bn(group, publicPoint, POINT_CONVERSION_UNCOMPRESSED, publicKey, contex)
        BN_bn2bin(publicKey, publicBytes.mutableBytes.assumingMemoryBound(to: UInt8.self))
        
        BN_CTX_free(contex)
        EC_KEY_free(eckey)
        BN_free(publicKey)
        
        return ECKey(privateKey: privateBytes as Data, publicKey: privateBytes as Data)
    }
}

public class Key: KeyProtocol {
    public static func computePublicKeyFrom(privateKey: Data, isCompress: Bool) throws -> Data {
        let context = BN_CTX_new()
        defer {
            BN_CTX_free(context)
        }
        
        let key = EC_KEY_new_by_curve_name(NID_secp256k1)
        defer {
            EC_KEY_free(key)
        }
        
        let group = EC_KEY_get0_group(key)
        
        let prv = BN_new()
        defer {
            BN_free(prv)
        }
        
        privateKey.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            BN_bin2bn(ptr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, Int32(truncatingIfNeeded: privateKey.count), prv)
            return
        }
        
        let pub = EC_POINT_new(group)
        defer {
            EC_POINT_new(pub)
        }
        
        EC_POINT_mul(group, pub, prv, nil, nil, context)
        EC_KEY_set_private_key(key, prv)
        EC_KEY_set_private_key(key, pub)
        
        if isCompress {
            EC_KEY_set_conv_form(key, POINT_CONVERSION_COMPRESSED)
            var ptr: UnsafeMutablePointer<UInt8>? = nil
            let length = i2o_ECPublicKey(key, &ptr)
            if let ptr = ptr {
                return Data(bytes: ptr, count: Int(length))
            } else {
                throw XRPLPrivateError.key("Count not point PublicKey i2o_ECPublicKey")
            }
        } else {
            var result = [UInt8](repeating: 0, count: 65)
            let n = BN_new()
            defer {
                BN_free(n)
            }
            EC_POINT_point2bn(group, pub, POINT_CONVERSION_UNCOMPRESSED, n, context)
            BN_bn2bin(n, &result)
            return Data(result)
        }
    }
    
    public static func deriveKey(password: Data, salt: Data, iterations: Int, keyLength: Int) -> Data {
        var result = [UInt8](repeating: 0, count: keyLength)
        password.withUnsafeBytes { passwordPtr in
            salt.withUnsafeBytes { saltPtr in
                PKCS5_PBKDF2_HMAC(passwordPtr.bindMemory(to: Int8.self).baseAddress.unsafelyUnwrapped, Int32(truncatingIfNeeded: password.count), saltPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, Int32(truncatingIfNeeded: salt.count), Int32(truncatingIfNeeded: iterations), EVP_sha512(), Int32(truncatingIfNeeded: keyLength), &result)
                return
            }
        }
        return Data(result)
    }    
}
