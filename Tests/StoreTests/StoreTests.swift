import XCTest
@testable import Store

final class StoreTests: XCTestCase {
    
    
    func testEmbedding() {
        
        guard
            let embedding1 = ClassEmbedding<Bar, Foo>(),
            let embedding2 = ClassEmbedding<Baz, Foo>() else {
            return XCTFail()
        }
        
        let bar = Bar()
        let foo = embedding1.cast(bar)
        
        if embedding2.downCast(foo) != nil {
            return XCTFail()
        }
        
        guard embedding1.downCast(foo) != nil else {
            return XCTFail()
        }
        
    }

    static var allTests = [
        ("testEmbedding", testEmbedding),
    ]
}


class Foo {}
class Bar : Foo {}
class Baz : Foo {}
