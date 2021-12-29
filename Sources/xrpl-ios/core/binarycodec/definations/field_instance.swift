import Foundation

public struct FieldInstance {
    
    let fieldName: String
    let fieldHeader: FieldHeader
    let fieldInfo: FieldInfo
    let ordinal: Int
    
    public init(fieldName: String, fieldHeader: FieldHeader, fieldInfo: FieldInfo) {
        self.fieldName = fieldName
        self.fieldHeader = fieldHeader
        self.fieldInfo = fieldInfo
        self.ordinal = fieldHeader.typeCode << 16 | fieldInfo.nth
    }
}
