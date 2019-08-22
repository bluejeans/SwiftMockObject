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
@testable import SwiftMockObject

class TestMockObject: XCTestCase {
    private var mock: MockExampleProtocol!

    override func setUp() {
        mock = MockExampleProtocol()
    }

    func testTimesCalled() {
        mock.simple()
        XCTAssertEqual(mock.getMockBehavior(.simple).timesCalled, 1)

        mock.simple()
        XCTAssertEqual(mock.getMockBehavior(.simple).timesCalled, 2)

        MOAssertTimesCalled(mock.methodReference(.simple), 2)
    }

    func testResetMockResetsTimesCalled() {
        mock.simple()
        XCTAssertEqual(mock.getMockBehavior(.simple).timesCalled, 1)

        mock.resetMock()
        XCTAssertEqual(mock.getMockBehavior(.simple).timesCalled, 0)
    }

    func testRecordedArgs() {
        mock.with(arg: 1)
        var args = mock.getMockBehavior(.withArg).recordedArgs
        XCTAssertEqual(args.count, 1)
        XCTAssertEqual(args[0].args as? [Int], [1])

        mock.with(arg: 2)
        args = mock.getMockBehavior(.withArg).recordedArgs
        XCTAssertEqual(args.count, 2)
        XCTAssertEqual(args[1].args as? [Int], [2])
    }

    func testResetMockResetsRecordedArgs() {
        mock.with(arg: 1)
        XCTAssertFalse(mock.getMockBehavior(.withArg).recordedArgs.isEmpty)

        mock.resetMock()
        XCTAssertTrue(mock.getMockBehavior(.withArg).recordedArgs.isEmpty)
    }

    func testCustomBehaviorToReturn() {
        XCTAssertTrue(mock.withReturn())

        mock.methodReference(.withReturn).setCustomBehaviorToReturn(false)
        XCTAssertFalse(mock.withReturn())
    }

    func testResetMockResetsCustomBehaviorToReturns() {
        mock.methodReference(.withReturn).setCustomBehaviorToReturn(false)

        mock.resetMock()

        XCTAssertTrue(mock.withReturn())
    }

    func testCustomBehaviorToReturnNil() {
        mock.methodReference(.withOptionalReturn).setCustomBehaviorToReturn("returned")
        XCTAssertEqual(mock.withOptionalReturn(), "returned")

        mock.methodReference(.withOptionalReturn).setCustomBehaviorToReturnNil()
        XCTAssertNil(mock.withOptionalReturn())
    }

    func testCustomBehavior() {
        mock.methodReference(.withReturnAndCallback).setCustomBehavior({ args -> Bool in
            guard let callback = args[0] as? (Int, String) -> Void else { XCTFail("Missing arg"); return true }
            callback(1, "hello")
            return false
        })

        var callbackInvoked = false
        let returnValue = mock.withReturn(callback: { int, string in
            XCTAssertEqual(int, 1)
            XCTAssertEqual(string, "hello")
            callbackInvoked = true
        })
        XCTAssertTrue(callbackInvoked)
        XCTAssertFalse(returnValue)
    }

    func testResetMockResetsCustomBehavior() {
        mock.methodReference(.withReturnAndCallback).setCustomBehavior({ args -> Bool in
            guard let callback = args[0] as? (Int, String) -> Void else { XCTFail("Missing arg"); return true }
            callback(1, "hello")
            return false
        })

        mock.resetMock()

        var callbackInvoked = false
        let returnValue = mock.withReturn(callback: { _, _ in
            callbackInvoked = true
        })
        XCTAssertFalse(callbackInvoked)
        XCTAssertTrue(returnValue)
    }

    func testCustomVoidBehavior() {
        mock.methodReference(.withMultipleArgsAndCallback).setCustomBehavior({ args in
            guard let callback = args[1] as? (Int, String) -> Void else { XCTFail("Missing arg"); return }
            callback(1, "hello")
        })

        var callbackInvoked = false
        mock.with(name: "name", callback: { int, string in
            XCTAssertEqual(int, 1)
            XCTAssertEqual(string, "hello")
            callbackInvoked = true
        })
        XCTAssertTrue(callbackInvoked)
    }

    func testResetMockResetsCustomVoidBehavior() {
        mock.methodReference(.withMultipleArgsAndCallback).setCustomBehavior({ args in
            guard let callback = args[1] as? (Int, String) -> Void else { XCTFail("Missing arg"); return }
            callback(1, "hello")
        })

        mock.resetMock()

        var callbackInvoked = false
        mock.with(name: "name", callback: { _, _ in
            callbackInvoked = true
        })
        XCTAssertFalse(callbackInvoked)
    }
}
