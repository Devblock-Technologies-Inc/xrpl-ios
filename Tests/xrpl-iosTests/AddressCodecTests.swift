import XCTest
@testable import xrpl_ios

class AddressCodecTest: XCTestCase {
    
    private let classicAddress: String = "rPWszQdxRJ8QrW3aTceUmBhXVFuxQZYUhk"
    //
    private let tag = 123
    private let exceptedXAddress: String = "XV51P7h3aM7GwT18dURcjAdx6NufeYeqsMjj5BFwy6JFbKq"
    
    private let addressCodec = AddressCodec()
    
    func testXAddress() throws {
        let xAddress = try? addressCodec.classicAddressToXAddress(classicAddress: classicAddress, tag: tag, isTestNetwork: false)
        
        XCTAssertEqual(xAddress, exceptedXAddress)
    }
    
    func testXAddressToClassicAddress() throws {
        let decoded = try addressCodec.xAddresToClassicAddress(xAddress: exceptedXAddress)
        let decodedClassicAddress = decoded.classicAddress
        let decodedTag = decoded.tag
        let decodedNetwork = decoded.isTestNetwork
        
        XCTAssertEqual(decodedClassicAddress, classicAddress)
        XCTAssertEqual(decodedTag, tag)
        XCTAssertEqual(decodedNetwork, false)
    }
}
