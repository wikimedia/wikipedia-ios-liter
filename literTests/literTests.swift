//
//  literTests.swift
//  literTests
//
//  Created by WMF on 10/11/19.
//  Copyright © 2019 WMF. All rights reserved.
//

import XCTest
@testable import liter

class literTests: XCTestCase {
    var vc: ViewController {
        return UIApplication.shared.windows.first?.rootViewController as! ViewController
    }

    override func setUp() {

    }

    override func tearDown() {
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        let title = "United_States"
        measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let loadExpectation = expectation(description: "load")
            startMeasuring()
            vc.load(with: title) { (result) in
                defer {
                    loadExpectation.fulfill()
                }
                switch result {
                case .failure:
                    XCTAssert(false)
                case .success:
                    break
                }
            }
            waitForExpectations(timeout: 30, handler: { (error) in
                self.stopMeasuring()
            })
        }
    }

}
