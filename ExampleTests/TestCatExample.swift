//
// Copyright 2019 Blue Jeans Network, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
import SwiftMockObject
@testable import Example

enum CatProtocolMethods {
    case feed
    case giveTreat
    case giveToy
    case call
}

class MockCat: MockObject<CatProtocolMethods>, CatProtocol {
    var isFull: Bool = false

    func feed(times: Int) {
        _onMethod(.feed, args: times)
    }

    func giveTreat() {
        _onMethod(.giveTreat)
    }

    func giveToy() -> Bool {
        return _onMethod(.giveToy, defaultReturn: false)
    }

    func call(name: String, response: @escaping (Bool) -> Void) {
        _onMethod(.call, args: name, response)
    }
}

class TestHuman: XCTestCase {
    private var cat: MockCat!
    private var human: Human!

    override func setUp() {
        cat = MockCat()
        human = Human(cat: cat)
    }

    func testWakeUp() {
        human.wakeUp(isFeelingGenerous: false)
        MOAssertArgumentEquals(cat.methodReference(.feed), 1, 1)
        MOAssertTimesCalled(cat.methodReference(.giveTreat), 0)
    }

    func testWakeUpWhenFeelingGenrous() {
        human.wakeUp(isFeelingGenerous: true)
        MOAssertArgumentEquals(cat.methodReference(.feed), 1, 5)
        MOAssertTimesCalled(cat.methodReference(.giveTreat), 1)
    }

    func testComeHomeWhenCatDoesNotRespond() {
        cat.methodReference(.call).setCustomBehavior({ args in
            guard let responseCallback = args[1] as? (Bool) -> Void else { XCTFail("Missing expected argument"); return }
            responseCallback(false)
        })

        human.comeHome()
        MOAssertArgumentEquals(cat.methodReference(.call), 1, "Socks")
        MOAssertTimesCalled(cat.methodReference(.giveToy), 0)
        XCTAssertFalse(human.isHappy)
    }

    func testComeHomeWhenCatRespondsAndRejectsToy() {
        cat.methodReference(.call).setCustomBehavior({ args in
            guard let responseCallback = args[1] as? (Bool) -> Void else { XCTFail("Missing expected argument"); return }
            responseCallback(true)
        })
        cat.methodReference(.giveToy).setCustomBehaviorToReturn(false)

        human.comeHome()
        MOAssertArgumentEquals(cat.methodReference(.call), 1, "Socks")
        MOAssertTimesCalled(cat.methodReference(.giveToy), 1)
        XCTAssertFalse(human.isHappy)
    }

    func testComeHomeWhenCatRespondsAndAcceptsToy() {
        cat.methodReference(.call).setCustomBehavior({ args in
            guard let responseCallback = args[1] as? (Bool) -> Void else { XCTFail("Missing expected argument"); return }
            responseCallback(true)
        })
        cat.methodReference(.giveToy).setCustomBehaviorToReturn(true)

        human.comeHome()
        MOAssertArgumentEquals(cat.methodReference(.call), 1, "Socks")
        MOAssertTimesCalled(cat.methodReference(.giveToy), 1)
        XCTAssertTrue(human.isHappy)
    }
}
