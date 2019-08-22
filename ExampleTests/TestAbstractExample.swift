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

enum DependencyProtocolMethods {
    case withOptionalArg
    case withComplexArg
    case withReturn
    case withOptionalReturn
    case withMultipleArgsAndCallback
}

class MockDependency: MockObject<DependencyProtocolMethods>, DependencyProtocol {
    func withOptional(arg: Int?) {
        _onMethod(.withOptionalArg, args: arg)
    }

    func withComplex(arg: ComplexArg) {
        _onMethod(.withComplexArg, args: arg)
    }

    func withReturn() -> Bool {
        return _onMethod(.withReturn, defaultReturn: true)
    }

    func withOptionalReturn() -> String? {
        return _onMethod(.withOptionalReturn, defaultReturn: nil)
    }

    func with(name: String, callback: @escaping (Int, String) -> Void) {
        _onMethod(.withMultipleArgsAndCallback, args: name, callback)
    }
}

class TestMainClass: XCTestCase {
    private var mock: MockDependency!
    private var mainClass: MainClass!

    override func setUp() {
        mock = MockDependency()
        mainClass = MainClass(dependency: mock)
    }

    func testInvokeDependencyTimes() {
        mainClass.invokeDependency(times: 0)
        // Asserting nil
        MOAssertArgumentNil(mock.methodReference(.withOptionalArg), 1)

        // Resetting mock
        mock.resetMock()

        mainClass.invokeDependency(times: 1)
        // Asserting times called
        MOAssertTimesCalled(mock.methodReference(.withOptionalArg), 1)
        // Asserting argument equals for last invocation
        // MOAssertArgumentEquals() also asserts that the method was called at least once
        MOAssertArgumentEquals(mock.methodReference(.withOptionalArg), 1, 1)

        mock.resetMock()

        mainClass.invokeDependency(times: 5)
        MOAssertTimesCalled(mock.methodReference(.withOptionalArg), 5)
        // Asserting argument equals for 4th invocation
        MOAssertArgumentEquals(mock.methodReference(.withOptionalArg), 1, 4, 4)
    }

    func testInvokeDependencyWithComplexArg() {
        mainClass.invokeDependencyWithComplexArg(countOf: [1, 2, 3])
        MOAssertTimesCalled(mock.methodReference(.withComplexArg), 1)
        // Getting an argument for more complex assertions
        // MOAssertArgumentEquals() can't be used because ComplexArg is not Equatable, so
        // get the argument and assert on its properties
        let actualArg: ComplexArg = MOAssertAndGetArgument(mock.methodReference(.withComplexArg), 1)!
        XCTAssertEqual(actualArg.key, "count")
        XCTAssertEqual(actualArg.value as? Int, 3)
    }

    func testOppositeOfDependency() {
        // Setting custom return behavior
        mock.methodReference(.withReturn).setCustomBehaviorToReturn(true)
        XCTAssertFalse(mainClass.oppositeOfDependency())

        mock.methodReference(.withReturn).setCustomBehaviorToReturn(false)
        XCTAssertTrue(mainClass.oppositeOfDependency())
    }

    func testDependencyWithDefaultValue() {
        mock.methodReference(.withOptionalReturn).setCustomBehaviorToReturn("hello")
        XCTAssertEqual(mainClass.dependencyWithDefaultValue("default"), "hello")

        mock.methodReference(.withOptionalReturn).setCustomBehaviorToReturnNil()
        XCTAssertEqual(mainClass.dependencyWithDefaultValue("default"), "default")
    }

    func testDoSomethingWithCallback() {
        // Setting custom behavior with args
        mock.methodReference(.withMultipleArgsAndCallback).setCustomBehavior({ args in
            guard let name = args[0] as? String else { XCTFail("Missing arg"); return }
            XCTAssertEqual(name, "Name")

            guard let callback = args[1] as? (Int, String) -> Void else { XCTFail("Missing arg"); return }
            callback(1, "hello")
        })

        mainClass.doSomething(name: "Name", callback: { result in
            XCTAssertEqual(result, "1 hello")
        })

        MOAssertArgumentEquals(mock.methodReference(.withMultipleArgsAndCallback), 1, "Name")
    }
}
