import XCTest
@testable import xrpl_ios

class AmountCodecTests: XCTestCase {
    
    func testHex() {
        let POS_SIGN_BIT_MASK: Int = 0x4000000000000000
        let ZERO_CURRENCY_AMOUNT_HEX: String = "8000000000000000"
        let posInt = 4611686018427387904
        
        let posSignBitMaskBytes = POS_SIGN_BIT_MASK.toByteArray()
        let posIntBytes = posInt.toByteArray()
        let zeroCurrencyAmountBytes = Array<UInt8>.init(hex: ZERO_CURRENCY_AMOUNT_HEX)
        
        print(posIntBytes.toHexString())
        print(zeroCurrencyAmountBytes)
        print(Int.max, Int.max.toByteArray())
        print(UInt.max, UInt.max.toByteArray())
        XCTAssertEqual(posInt, POS_SIGN_BIT_MASK)
        XCTAssertEqual(posSignBitMaskBytes.toHexString(), "4000000000000000")
    }
}
