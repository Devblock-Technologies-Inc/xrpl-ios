import Foundation

/// General XRPL Address Codec Exception.
enum XRPLAddressCodecException: XRPLException {
    case unexpectedPayloadLength
    case encodingFailed(String)
    case decodingFailed(String)
    case prefixIncorrect
    case seedLength(UInt)
    case codecException(String)
    case accountLength
    case invalidTag
}

extension XRPLAddressCodecException: LocalizedError {
    var localizedDescription: String? {
        switch self {
        case .unexpectedPayloadLength:
            return NSLocalizedString("unexpected_payload_length: len(bytestring) does not match expected_length. Ensure that the bytes are a bytestring.", comment: "")
        case .encodingFailed(let message):
            return NSLocalizedString("Encoding failed - \(message)", comment: "")
        case .prefixIncorrect:
            return NSLocalizedString("Provided prefix is incorrect", comment: "")
        case .decodingFailed(let message):
            return NSLocalizedString("Decoding failed - \(message)", comment: "")
        case .seedLength(let seedLength):
            return NSLocalizedString("Entropy must have length \(seedLength)", comment: "")
        case .accountLength:
            return NSLocalizedString("Account ID must be 20 bytes", comment: "")
        case .invalidTag:
            return NSLocalizedString("Invalid tag", comment: "")
        case .codecException(let description):
            return NSLocalizedString(description, comment: "")
        }
    }
}
