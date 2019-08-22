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

class TestAssertions: XCTestCase {
    private var mock: MockExampleProtocol!

    private var isExpectingFailure: Bool!
    private var didRecordFailure: Bool!

    override func setUp() {
        mock = MockExampleProtocol()
        isExpectingFailure = false
        didRecordFailure = false
    }

    override func recordFailure(withDescription description: String, inFile filePath: String, atLine lineNumber: Int, expected: Bool) {
        // Override recordFailure so that the test doesn't fail if we are expecting the assertion to fail
        if !isExpectingFailure {
            // This is an unexpected failure, call super to actually fail the test
            super.recordFailure(withDescription: description, inFile: filePath, atLine: lineNumber, expected: expected)
        } else {
            didRecordFailure = true
        }
    }

    private func expectNextAssertionToFail() {
        isExpectingFailure = true
    }

    /// Fails the test if a previous failure was *not* recorded
    private func assertFailureWasRecorded(file: String = #file, line: UInt = #line) {
        if !didRecordFailure {
            super.recordFailure(withDescription: "Expected a recorded failure", inFile: file, atLine: Int(line), expected: true)
        }
    }

    func testAssertTimesCalledPasses() {
        mock.simple()
        MOAssertTimesCalled(mock.methodReference(.simple), 1)
    }

    func testAssertTimesCalledFails() {
        mock.simple()
        expectNextAssertionToFail()
        MOAssertTimesCalled(mock.methodReference(.simple), 2)
        assertFailureWasRecorded()
    }

    func testAssertAndGetArgument() {
        mock.with(arg: 42)
        let arg: Int = MOAssertAndGetArgument(mock.methodReference(.withArg), 1)!
        XCTAssertEqual(arg, 42)
    }

    func testAssertAndGetArgumentNotCalledEnoughTimes() {
        expectNextAssertionToFail()
        let arg: Int? = MOAssertAndGetArgument(mock.methodReference(.withArg), 1)
        XCTAssertNil(arg)
        assertFailureWasRecorded()
    }

    func testAssertAndGetArgumentNotCalledWithEnoughArgs() {
        mock.with(arg: 42)
        expectNextAssertionToFail()
        let arg: Any? = MOAssertAndGetArgument(mock.methodReference(.withArg), 2)
        XCTAssertNil(arg)
        assertFailureWasRecorded()
    }

    func testAssertAndGetArgumentTypeMismatch() {
        mock.with(arg: 42)
        expectNextAssertionToFail()
        let arg: String? = MOAssertAndGetArgument(mock.methodReference(.withArg), 1)
        XCTAssertNil(arg)
        assertFailureWasRecorded()
    }

    func testAssertAndGetArgumentAtTime() {
        mock.with(arg: 42)
        mock.with(arg: 24)
        let arg: Int = MOAssertAndGetArgument(mock.methodReference(.withArg), 1, 2)!
        XCTAssertEqual(arg, 24)
    }

    func testAssertAndGetArgumentAtTimeNotCalledEnoughTimes() {
        mock.with(arg: 42)
        expectNextAssertionToFail()
        let arg: Int? = MOAssertAndGetArgument(mock.methodReference(.withArg), 1, 2)
        XCTAssertNil(arg)
        assertFailureWasRecorded()
    }

    func testAssertArgumentEquals() {
        mock.with(arg: 42)
        MOAssertArgumentEquals(mock.methodReference(.withArg), 1, 42)
    }

    func testAssertArgumentEqualsFails() {
        mock.with(arg: 42)
        expectNextAssertionToFail()
        MOAssertArgumentEquals(mock.methodReference(.withArg), 1, 24)
        assertFailureWasRecorded()
    }

    func testAssertArgumentEqualsAtTime() {
        mock.with(arg: 42)
        mock.with(arg: 24)
        MOAssertArgumentEquals(mock.methodReference(.withArg), 1, 2, 24)
    }

    func testAssertArgumentNil() {
        mock.withOptional(arg: nil)
        MOAssertArgumentNil(mock.methodReference(.withOptionalArg), 1)
    }

    func testAssertArgumentNilAtTime() {
        mock.withOptional(arg: 42)
        mock.withOptional(arg: nil)
        MOAssertArgumentNil(mock.methodReference(.withOptionalArg), 1, 2)
    }

    func testAssertArgumentNilFails() {
        mock.withOptional(arg: 42)
        expectNextAssertionToFail()
        MOAssertArgumentNil(mock.methodReference(.withOptionalArg), 1)
        assertFailureWasRecorded()
    }
}
