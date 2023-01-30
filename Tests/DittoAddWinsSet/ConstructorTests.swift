//
//  File.swift
//  
//
//  Created by Maximilian Alexander on 1/30/23.
//

import XCTest
@testable import DittoAddWinsSet

class ConstructorTests: XCTestCase {

    func testSetDeDuplication() throws {
        let addWinsSet = DittoAddWinsSet(dictionary: [
            "foo": "bar",
            "1": 20,
            "2": 20,
            "zoo": "bar",
        ])
        XCTAssertEqual(addWinsSet.values.count, 2)
        let dictionary = try addWinsSet.asDictionary()
        print(dictionary.keys)
        XCTAssertEqual(dictionary.count, 2)
    }

    func testComplexSetDuplicationWithMaps() {
        let addWinsSet = DittoAddWinsSet(dictionary: [
            "foo": ["a": 1],
            "1": 20,
            "2": 20,
            "zoo": ["a": 1],
        ])
        XCTAssertEqual(addWinsSet.values.count, 2)
    }
    
    func testComplexSetDuplicationWithArrays() {
        let addWinsSet = DittoAddWinsSet(dictionary: [
            "foo": [1, 2],
            "1": 20,
            "2": 20,
            "zoo": [1, 3],
        ])
        XCTAssertEqual(addWinsSet.values.count, 3)
    }
}
