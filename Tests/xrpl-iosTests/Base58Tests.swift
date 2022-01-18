import XCTest
@testable import xrpl_ios

// swiftlint:disable all
class Base58Tests: XCTestCase {

    func testEncodeDecodeString() throws {
        let decoded: Data = "Hello World".data
        let encoded: String = "JxErpTiA7PhnBMd"
        
        XCTAssertEqual(XBase58.encode(decoded), encoded)
        XCTAssertEqual(XBase58.decode(encoded), decoded)
    }
    
    func testEncodeChecked() throws {
        let input: [UInt8] = [6, 161, 159, 136, 34, 110, 33, 238, 14, 79, 14, 218, 133, 13, 109, 40, 194, 236, 153, 44, 61, 157, 254]
        let encoded = XBase58Check.encode(Data(input))
        XCTAssertEqual(encoded, "tzrYsqqTg9HdizZGbNj5UPmAuZfCWVxFPtRA")
    }
    
    func testDecodeChecked() throws {
        let input = "tzrYsqqTg9HdizZGbNj5UPmAuZfCWVxFPtRA"
        let expectedOutputData: [UInt8] = [6, 161, 159, 136, 34, 110, 33, 238, 14, 79, 14, 218, 133, 13, 109, 40, 194, 236, 153, 44, 61, 157, 254]
        
        let actualOutput = try XBase58Check.decode(input)
        XCTAssertEqual(actualOutput, expectedOutputData)
    }

}
// swiftlint:enable all
