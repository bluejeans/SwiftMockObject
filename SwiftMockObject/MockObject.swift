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

internal class MockArgsRecord {
    let args: [Any?]

    init(args: [Any?]) {
        self.args = args
    }
}

internal class MockBehavior {
    var timesCalled = 0
    var customBehavior: (([Any?]) -> Any)?
    var customVoidBehavior: (([Any?]) -> Void)?
    var recordedArgs: [MockArgsRecord] = []
}

/**
 A reference to a method that supports stubbing out behaviors and return values
 */
public class MethodReference<MethodType: Hashable> {
    internal let object: MockObject<MethodType>
    internal let method: MethodType

    fileprivate init(object: MockObject<MethodType>, method: MethodType) {
        self.object = object
        self.method = method
    }

    /**
     Sets a return value
     */
    public func setCustomBehaviorToReturn(_ toReturn: Any) {
        object.getMockBehavior(method).customBehavior = { _ in
            return toReturn
        }
        object.getMockBehavior(method).customVoidBehavior = nil
    }

    /**
     Sets a nil return value
     */
    public func setCustomBehaviorToReturnNil() {
        setCustomBehaviorToReturn(Optional<Any>.none as Any) // swiftlint:disable:this syntactic_sugar
    }

    /**
     Allows custom behavior to be specified. The arguments are passed to
     the behavior as an `[Any]`, so you may have to cast.
     */
    public func setCustomBehavior(_ behavior: @escaping (([Any]) -> Any)) {
        object.getMockBehavior(method).customBehavior = behavior
        object.getMockBehavior(method).customVoidBehavior = nil
    }

    /**
     Allows custom behavior to be specified. The arguments are passed to
     the behavior as an `[Any]`, so you may have to cast.
     */
    public func setCustomBehavior(_ behavior: @escaping (([Any]) -> Void)) {
        object.getMockBehavior(method).customBehavior = nil
        object.getMockBehavior(method).customVoidBehavior = behavior
    }
}

/**
 Superclass for mock objects

 To create a mock for `DependencyProtocol`, create an enum (e.g. `DependencyProtocolMethods`)
 representing the methods of the protocol. The enum will serve as the `MethodType` for the mock.

 Then create a mock class that subclasses `MockObject<DependencyProtocolMethods>` and conforms
 to `DependencyProtocol`. The mock class can then use `_onMethod()` in its implementation
 to both track method invocations and arguments for later assertion and to provide stubbing functionality.

 To stub out behavior, use `methodReference()` to get a `MethodReference` and use `setCustomBehavior()`
 on the `MethodReference`.

 # Example
 ````
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

     func with(name: String, callback: @escaping (Int, String) -> Void) {
        _onMethod(.withMultipleArgsAndCallback, args: name, callback)
     }
 }
 ````
 */
open class MockObject<MethodType: Hashable> {
    private var mockBehaviors: [MethodType: MockBehavior] = [:]

    public init() {}

    internal func getMockBehavior(_ method: MethodType) -> MockBehavior {
        let mockBehavior = mockBehaviors[method]
        if let nnMockBehavior = mockBehavior {
            return nnMockBehavior
        } else {
            let nnMockBehavior = MockBehavior()
            mockBehaviors[method] = nnMockBehavior
            return nnMockBehavior
        }
    }

    @discardableResult
    private func internalOnMethod(_ method: MethodType, args: [Any?]) -> Any? {
        let mockBehavior = getMockBehavior(method)
        mockBehavior.timesCalled += 1
        mockBehavior.recordedArgs.append(MockArgsRecord(args: args))
        if let behavior = mockBehavior.customBehavior {
            return behavior(args)
        } else if let behavior = mockBehavior.customVoidBehavior {
            behavior(args)
            return nil
        }
        return nil
    }

    /**
     Records a method invocation and its associated arguments
     */
    public func _onMethod(_ method: MethodType, args: Any?...) {
        internalOnMethod(method, args: args)
    }

    /**
     Records a method invocation and its associated arguments, returning the value in `defaultReturn`
     unless the method has a custom return set using `setCustomBehaviorToReturn()`.

     If you want the mock to return a different value, use `mock.methodReference(.method).setCustomBehaviorToReturn(newValue)`.
     */
    public func _onMethod<ReturnType>(_ method: MethodType, defaultReturn: ReturnType, args: Any?...) -> ReturnType {
        let returnValue = internalOnMethod(method, args: args)
        return (returnValue as? ReturnType) ?? defaultReturn
    }

    /**
     Resets all recorded method invocations and custom behaviors
     */
    public func resetMock() {
        mockBehaviors.removeAll()
    }

    /**
     Returns a `MethodReference` on which you can call `setCustomBehavior()` to stub out functionality
     */
    public func methodReference(_ method: MethodType) -> MethodReference<MethodType> {
        return MethodReference<MethodType>(object: self, method: method)
    }
}
