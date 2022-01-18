import XCTest
@testable import xrpl_ios

class BinaryCodecTests: XCTestCase {
    
    func testDefinationDecoding() throws {
        let defination = try? Definations.loadDefinations()
        
        XCTAssertNotNil(defination)
    }
}
