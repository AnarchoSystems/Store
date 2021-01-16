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
    
    
    func testPairing() {
        
        var pair = Pair(first: 42, second: 1337)
        
        let lens = Pair<Int,Int>.Lens.first.paired(with: \Pair<Int,Int>.second)
        
        lens.apply(to: &pair) {paired in
            paired.withBoth{first, second in
                let oldFirst = first
                first += second
                second += oldFirst
            }
        }
        
        XCTAssertEqual(pair.first, pair.second)
        
    }
    

    static var allTests = [
        ("testEmbedding", testEmbedding),
        ("testPairing", testPairing)
    ]
}


class Foo {}
class Bar : Foo {}
class Baz : Foo {}


struct Pair<T,U> : Lensable {
    var first : T
    var second : U
}
