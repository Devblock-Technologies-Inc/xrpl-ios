import Foundation

public enum XRPLBinaryCodeException: XRPLException {
    case binaryCodec(String)
    case binaryParser(String)
    case binarySerializer(String)
    case definations(String)
    case types(String)
}

extension XRPLBinaryCodeException: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .binaryCodec(let message):
            return NSLocalizedString("BinaryCodec - \(message)", comment: "")
        case .binaryParser(let message):
            return NSLocalizedString("BinaryParser - \(message)", comment: "")
        case .binarySerializer(let message):
            return NSLocalizedString("BinarySerializer - \(message)", comment: "")
        case .definations(let message):
            return NSLocalizedString("Difinations - \(message)", comment: "")
        case .types(let message):
            return NSLocalizedString("Types - \(message)", comment: "")
        }
    }
}
