import Foundation

public enum FieldElement: Codable {
    case fieldName(String)
    case fieldInfo(FieldInfo)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let name = try? container.decode(String.self) {
            self = .fieldName(name)
            return
        }
        if let info = try? container.decode(FieldInfo.self) {
            self = .fieldInfo(info)
            return
        }
        throw DecodingError.typeMismatch(FieldElement.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for FieldElement"))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fieldName(let name):
            try container.encode(name)
        case .fieldInfo(let info):
            try container.encode(info)
        }
    }
    
    public var value: Any {
        switch self {
        case .fieldName(let name):
            return name
        case .fieldInfo(let info):
            return info
        }
    }
}

/// Maps and helpers providing serialization-related information about fields.
public struct Definations: Codable {
    public let types, ledgerEntryTypes: [String: Int]
    public let fields: [[FieldElement]]
    public let transactionResults, transactionTypes: [String: Int]
    
    enum CodingKeys: String, CodingKey {
        case types = "TYPES"
        case ledgerEntryTypes = "LEDGER_ENTRY_TYPES"
        case fields = "FIELDS"
        case transactionResults = "TRANSACTION_RESULTS"
        case transactionTypes = "TRANSACTION_TYPES"
    }
    
    private var fieldInfoMap: [String: FieldInfo] = [:]
    private var fieldHeaderNameMap: [FieldHeader: String] = [:]
    private var transactionTypesCodeToStringMap: [Int: String] = [:]
    private var transactionResultsCodeToStringMap: [Int: String] = [:]
    private var ledgerEntryTypesCodeToStringMap: [Int: String] = [:]
    
    private struct TypeCode {
        let typeName: String
        let typeCode: Int
    }
    
    private let unknownTypeCode = TypeCode(typeName: "Unknown", typeCode: -2)
    private let invalidFieldInfo = FieldInfo(nth: -1, isVLEncoded: false, isSerialized: false, isSigningField: false, type: "Unknown")
    private let invalidFieldName = "Unknown"
    private let invalidTransactionType = TypeCode(typeName: "Invalid", typeCode: -1)
    private let invalidTransactionResult = TypeCode(typeName: "temINVALID", typeCode: -277)
    private let invalidLedgerEntryType = TypeCode(typeName: "Invalid", typeCode: -1)
    
    /// Loads JSON from the definitions file and converts it to a preferred format.
    /// The definitions file contains information required for the XRP Ledger's canonical binary serialization format:
    /// `Serialization <https://xrpl.org/serialization.html>`
    public static func loadDefinations(_ fileName: String = "definations", type: String = "json") throws -> Definations {
        guard let path = Bundle.module.url(forResource: fileName, withExtension: type) else {
            throw XRPLBinaryCodeException.difinations("\(fileName).\(type) not found")
        }
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        var definations = try decoder.decode(Definations.self, from: data)
        
        for field in definations.fields {
            guard
                let fieldName = field.first?.value as? String,
                let fieldInfo = field.last?.value as? FieldInfo,
                let typeCode = definations.types[fieldInfo.type] else {
                    throw XRPLBinaryCodeException.difinations("Malformed definitions.json file")
                }

            let header = FieldHeader(typeCode: typeCode, fieldCode: fieldInfo.nth)
            definations.fieldInfoMap[fieldName] = fieldInfo
            definations.fieldHeaderNameMap[header] = fieldName
        }
        
        definations.transactionTypesCodeToStringMap = definations.transactionTypes.swapKeyValues()
        definations.transactionResultsCodeToStringMap = definations.transactionResults.swapKeyValues()
        definations.ledgerEntryTypesCodeToStringMap = definations.ledgerEntryTypes.swapKeyValues()
        
        return definations
    }
    
    /// Returns the serialization data type for the given field name.
    /// `Serialization Type List <https://xrpl.org/serialization.html#type-list>`
    /// - Parameter fieldName: The name of the field to get the serialization data type for.
    /// - Returns: The serialization data type for the given field name.
    public func getFieldTypeName(_ fieldName: String) -> String {
        return fieldInfoMap[fieldName]?.type ?? unknownTypeCode.typeName
    }
    
    /// Returns the type code associated with the given field.
    /// `Serialization Type Codes <https://xrpl.org/serialization.html#type-codes>`
    /// - Parameter fieldName: The name of the field get a type code for.
    /// - Returns: The type code associated with the given field name.
    public func getFieldTypeCode(_ fieldName: String) -> Int {
        let fieldTypeName = getFieldTypeName(fieldName)
        let fieldTypeCode = types[fieldTypeName]
        
        return fieldTypeCode ?? unknownTypeCode.typeCode
    }
    
    /// Returns the field code associated with the given field.
    /// `Serialization Field Codes <https://xrpl.org/serialization.html#field-codes>`
    /// - Parameter fieldName: The name of the field to get a field code for.
    /// - Returns: The field code associated with the given field.
    public func getFieldCode(_ fieldName: String) -> Int {
        return fieldInfoMap[fieldName]?.nth ?? invalidFieldInfo.nth
    }
    
    /// Returns a FieldHeader object for a field of the given field name.
    /// - Parameter fieldName: The name of the field to get a FieldHeader for.
    /// - Returns: A `FieldHeader` object for a field of the given field name.
    public func getFieldHeader(from fieldName: String) -> FieldHeader {
        return FieldHeader(typeCode: getFieldTypeCode(fieldName), fieldCode: getFieldCode(fieldName))
    }
    
    /// Returns the field name described by the given FieldHeader object.
    /// - Parameter fieldHeader: The header to get a field name for.
    /// - Returns: The name of the field described by the given `FieldHeader`.
    public func getFieldName(from fieldHeader: FieldHeader) -> String {
        return fieldHeaderNameMap[fieldHeader] ?? invalidFieldName
    }
    
    /// Return a FieldInstance object for the given field name.
    /// - Parameter fieldName: The name of the field to get a FieldInstance for.
    /// - Returns: A `FieldInstance` object for the given field name.
    public func getFieldInstance(_ fieldName: String) -> FieldInstance {
        let fieldInfo = fieldInfoMap[fieldName] ?? invalidFieldInfo
        let fieldHeader = getFieldHeader(from: fieldName)
        
        return FieldInstance(fieldName: fieldName, fieldHeader: fieldHeader, fieldInfo: fieldInfo)
    }
    
    /// Return an integer representing the given transaction type string in an enum.
    /// -  Parameter transactionType: The name of the transaction type to get the enum value for.
    /// - Returns: An integer representing the given transaction type string in an enum.
    public func getTransactionTypeCode(_ transactionType: String) -> Int {
        return transactionTypes[transactionType] ?? invalidTransactionType.typeCode
    }
    
    /// Return string representing the given transaction type from the enum.
    /// - Parameter transactionType: The enum value of the transaction type.
    /// - Returns: The string name of the transaction type.
    public func getTransactionTypeName(_ transactionType: Int) -> String {
        return transactionTypesCodeToStringMap[transactionType] ?? invalidTransactionType.typeName
    }
    
    /// Return an integer representing the given transaction result string in an enum.
    /// - Parameter transactionResultType: The name of the transaction result type to get the enum value for.
    /// - Returns: An integer representing the given transaction result type string in an enum.
    public func getTransactionResultCode(_ transactionResultType: String) -> Int {
        return transactionResults[transactionResultType] ?? invalidTransactionResult.typeCode
    }
    
    /// Return string representing the given transaction result type from the enum.
    /// - Parameter transactionResultType: The enum value of the transaction result type.
    /// - Returns: The string name of the transaction result type.
    public func getTransactionResultName(_ transactionResultType: Int) -> String {
        return transactionResultsCodeToStringMap[transactionResultType] ?? invalidTransactionResult.typeName
    }
    
    /// Return an integer representing the given ledger entry type string in an enum.
    /// - Parameter ledgerEntryType: The name of the ledger entry type to get the enum value for.
    /// - Returns:
            An integer representing the given ledger entry type string in an enum.
    public func getLedgerEntryTypeCode(_ ledgerEntryType: String) -> Int {
        return ledgerEntryTypes[ledgerEntryType] ?? invalidLedgerEntryType.typeCode
    }
    
    /// Return string representing the given ledger entry type from the enum.
    /// - Parameter ledgerEntryType: The enum value of the ledger entry type.
    /// - Returns: The string name of the ledger entry type.
    public func getLedgerEntryTypeName(_ ledgerEntryType: Int) -> String {
        return ledgerEntryTypesCodeToStringMap[ledgerEntryType] ?? invalidLedgerEntryType.typeName
    }
}

extension Dictionary where Value: Hashable {
    public func swapKeyValues() -> [Value: Key] {
        assert(Set(values).count == keys.count, "Values must be unique")
        var newDictionary = [Value: Key]()
        for (k, v) in self {
            newDictionary[v] = k
        }
        return newDictionary
    }
}
