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

import Foundation
import XCTest

extension XCTestCase {
    /**
     Asserts that the method was called `expectedTimes` times
     */
    public func MOAssertTimesCalled<MethodType>(_ methodReference: MethodReference<MethodType>, _ expectedTimes: Int, file: String = #file, line: UInt = #line) {
        let actualTimes = methodReference.object.getMockBehavior(methodReference.method).timesCalled
        if actualTimes != expectedTimes {
            recordFailure(withDescription: "Expected \(methodReference.method) to be called \(expectedTimes) time(s) but was actually called \(actualTimes) time(s).", inFile: file, atLine: Int(line), expected: true)
        }
    }

    /**
     Asserts that the method was called at least once and returns the argument
     - Parameters:
         - whichArg: The index of the argument to the method, starting from 1
     - Returns: The argument as `T?`, which may need to be cast to the expected type.

        Example:
        ````
        let arg: String = MOAssertAndGetArgument(mock.methodReference(.method), 1)!
         ````
     */
    public func MOAssertAndGetArgument<MethodType, T>(_ methodReference: MethodReference<MethodType>, _ whichArg: Int, file: String = #file, line: UInt = #line) -> T? {
        return MOAssertAndGetArgument(methodReference, whichArg, nil, file: file, line: line)
    }

    /**
     Asserts that the method was called at least `whichTime` times and returns the argument
     - Parameters:
         - whichArg: The index of the argument to the method, starting from 1
         - whichTime: The invocation for which to get the argument, starting from 1. `nil` uses the last invocation.
     - Returns: The argument as `T?`, which may need to be cast to the expected type.

         Example:
         ````
         let arg: String = MOAssertAndGetArgument(mock.methodReference(.method), 1)!
         ````
     */
    public func MOAssertAndGetArgument<MethodType, T>(_ methodReference: MethodReference<MethodType>, _ whichArg: Int, _ whichTime: Int?, file: String = #file, line: UInt = #line) -> T? {
        return internalMOAssertAndGetArgument(methodReference, whichArg, whichTime, file: file, line: line).0
    }

    /**
     Asserts that the method was called at least once and that the argument was equal to `expectedValue`
     - Parameters:
         - whichArg: The index of the argument to the method, starting from 1
     */
    public func MOAssertArgumentEquals<MethodType, T: Equatable>(_ methodReference: MethodReference<MethodType>, _ whichArg: Int, _ expectedValue: T, file: String = #file, line: UInt = #line) {
        MOAssertArgumentEquals(methodReference, whichArg, nil, expectedValue, file: file, line: line)
    }

    /**
     Asserts that the method was called at least `whichTime` times and that the argument was equal to `expectedValue`
     - Parameters:
         - whichArg: The index of the argument to the method, starting from 1
         - whichTime: The invocation for which to get the argument, starting from 1. `nil` uses the last invocation.
     */
    public func MOAssertArgumentEquals<MethodType, T: Equatable>(_ methodReference: MethodReference<MethodType>, _ whichArg: Int, _ whichTime: Int?, _ expectedValue: T, file: String = #file, line: UInt = #line) {
        let (value, error)  = internalMOAssertAndGetArgument(methodReference, whichArg, whichTime, file: file, line: line) as (T?, Bool)
        guard !error else {return}
        if value != expectedValue {
            recordFailure(withDescription: "Argument #\(whichArg): expected \(expectedValue) but got \(String(describing: value))", inFile: file, atLine: Int(line), expected: true)
        }
    }

    /**
     Asserts that the method was called at least once and that the argument was nil
     - Parameters:
         - whichArg: The index of the argument to the method, starting from 1
     */
    public func MOAssertArgumentNil<MethodType>(_ methodReference: MethodReference<MethodType>, _ whichArg: Int, file: String = #file, line: UInt = #line) {
        MOAssertArgumentNil(methodReference, whichArg, nil, file: file, line: line)
    }

    /**
    Asserts that the method was called at least `whichTime` times and that the argument was nil
    - Parameters:
        - whichArg: The index of the argument to the method, starting from 1
        - whichTime: The invocation for which to get the argument, starting from 1. `nil` uses the last invocation.
    */
    public func MOAssertArgumentNil<MethodType>(_ methodReference: MethodReference<MethodType>, _ whichArg: Int, _ whichTime: Int?, file: String = #file, line: UInt = #line) {
        let (value, error) = internalMOAssertAndGetArgument(methodReference, whichArg, whichTime, file: file, line: line) as (AnyObject??, Bool)
        guard !error else {return}
        if value != nil {
            recordFailure(withDescription: "Argument #\(whichArg): expected nil but got \(String(describing: value))", inFile: file, atLine: Int(line), expected: true)
        }
    }

    private func internalMOAssertAndGetArgument<MethodType, T>(_ methodReference: MethodReference<MethodType>, _ whichArg: Int, _ whichTime: Int?, file: String, line: UInt) -> (T?, Bool) {
        let recordedArgs = methodReference.object.getMockBehavior(methodReference.method).recordedArgs
        let whichTime = whichTime ?? max(recordedArgs.count, 1)
        guard recordedArgs.count >= whichTime else {
            recordFailure(withDescription: "\(methodReference.method) was not called \(whichTime) time(s) (was called \(recordedArgs.count) time(s)).", inFile: file, atLine: Int(line), expected: true)
            return (nil, true)
        }

        let args = recordedArgs[whichTime - 1].args
        guard args.count >= whichArg else {
            recordFailure(withDescription: "\(methodReference.method) was not called with at least \(whichArg) arguments.", inFile: file, atLine: Int(line), expected: true)
            return (nil, true)
        }

        let arg = args[whichArg - 1]
        guard arg != nil else {
            return (nil, false) // This is not an error because nil can be a valid argument. Unfortunately, Swift does not have a way to check that T is an Optional type.
        }
        guard arg is T else {
            recordFailure(withDescription: "Argument #\(whichArg): expected type \(T.self) but got type \(type(of: (arg) as AnyObject))", inFile: file, atLine: Int(line), expected: true)
            return (nil, true)
        }

        return ((arg as! T), false)
    }
}
