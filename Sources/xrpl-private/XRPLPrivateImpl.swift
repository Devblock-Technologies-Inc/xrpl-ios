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

        var result = [UInt8](repeating: 0, count: Int(SHA256_DIGEST_LENGTH))
        
        result.withUnsafeMutableBytes { resultPtr in
            data.withUnsafeBytes { dataPtr in
                SHA256(dataPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, data.count, resultPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped)
                return
            }
        }
        
        return Data(result)
    }
    
    public static func sha256sha256(_ data: Data) throws -> Data {
        return try sha256(try sha256(data))
    }
    
    public static func ripemd160(_ data: Data) -> Data {
        
        var result = [UInt8](repeating: 0, count: Int(RIPEMD160_DIGEST_LENGTH))
        
        result.withUnsafeMutableBytes { resultPtr in
            data.withUnsafeBytes { dataPtr in
                RIPEMD160(dataPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, data.count, resultPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped)
                return
            }
        }
        
        return Data(result)
    }
    
    public static func hmacsha512(_ data: Data, key: Data) throws -> Data {
        var length = UInt32(SHA512_DIGEST_LENGTH)
        
        var result = [UInt8](repeating: 0, count: Int(length))
        
        result.withUnsafeMutableBytes { resultPtr in
            key.withUnsafeBytes { keyPtr in
                data.withUnsafeBytes { dataPtr in
                    HMAC(EVP_sha512(), keyPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, Int32(truncatingIfNeeded: key.count), dataPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, data.count, resultPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, &length)
                    return
                }
            }
        }
        
        return Data(result)
    }
    
    public static func hmacsha256(_ data: Data, key: Data, iv: Data, macData: Data) throws -> Data {
        let context = HMAC_CTX_new()
        defer {
            HMAC_CTX_free(context)
        }
        
        HMAC_CTX_reset(context)
        
        key.withUnsafeBytes { keyPtr in
            HMAC_Init_ex(context, keyPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, Int32(truncatingIfNeeded: key.count), EVP_sha512(), nil)
            return
        }
        
        iv.withUnsafeBytes { ivPtr in
            HMAC_Update(context, ivPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, iv.count)
            return
        }
        
        data.withUnsafeBytes { dataPtr in
            HMAC_Update(context, dataPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, data.count)
            return
        }
        
        macData.withUnsafeBytes { macDataPtr in
            HMAC_Update(context, macDataPtr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, macData.count)
            return
        }
        
        var length = UInt32(SHA256_DIGEST_LENGTH)
        
        var result = [UInt8](repeating: 0, count: Int(length))
        
        result.withUnsafeMutableBytes { ptr in
            HMAC_Final(context, ptr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped, &length)
            return
        }
        
        return Data(result)
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
        let context = BN_CTX_new()
        defer {
            BN_CTX_free(context)
        }
        
        let eckey = EC_KEY_new_by_curve_name(NID_secp256k1)
        defer {
            EC_KEY_free(eckey)
        }
        EC_KEY_generate_key(eckey)
        
        let group = EC_KEY_get0_group(eckey)
        
        let privateKey = EC_KEY_get0_private_key(eckey)
        var privateBytes = [UInt8](repeating: 0, count: 32)
        
        privateBytes.withUnsafeMutableBytes { ptr in
            BN_bn2bin(privateKey, ptr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped)
            return
        }
        
        let publicPoint = EC_KEY_get0_public_key(eckey)
        
        let publicKey = BN_new()
        defer {
            BN_free(publicKey)
        }
        
        EC_POINT_point2bn(group, publicPoint, POINT_CONVERSION_UNCOMPRESSED, publicKey, context)
        
        var publicBytes = [UInt8](repeating: 0, count: 65)
        publicBytes.withUnsafeMutableBytes { ptr in
            BN_bn2bin(publicKey, ptr.bindMemory(to: UInt8.self).baseAddress.unsafelyUnwrapped)
            return
        }
        
        return ECKey(privateKey: Data(privateBytes), publicKey: Data(publicBytes))
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
