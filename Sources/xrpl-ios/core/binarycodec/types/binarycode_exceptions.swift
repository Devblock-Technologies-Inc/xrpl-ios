import Foundation

public enum XRPLBinaryCodeException: XRPLException {
    case binaryParser(String)
}

extension XRPLBinaryCodeException: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .binaryParser(let message):
            return NSLocalizedString("BinaryParser - \(message)", comment: "")
        }
    }
}
