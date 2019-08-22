# SwiftMockObject
Protocol-based mocks for Swift unit testing

![platform: iOS | macOS | tvOS](https://img.shields.io/badge/platform-iOS%20%7C%20macOS%20%7C%20tvOS-lightgrey.svg)
[![license](https://img.shields.io/badge/license-Apache_License_2.0-blue.svg)](./LICENSE)
[![carthage: compatible](https://img.shields.io/badge/carthage-compatible-brightgreen.svg)](https://github.com/Carthage/Carthage)

<!-- MarkdownTOC autolink="true" autoanchor="true" levels="1,2,3" -->

- [Requirements](#requirements)
- [Installation](#installation)
    - [Carthage](#carthage)
- [Features](#features)
- [Usage](#usage)
    - [Creating a mock](#creating-a-mock)
    - [Stubbing](#stubbing)
    - [Asserting method calls and arguments](#asserting-method-calls-and-arguments)
    - [More examples](#more-examples)
- [Credits](#credits)
- [License](#license)

<!-- /MarkdownTOC -->

<a id="requirements"></a>
## Requirements
* iOS 8.0+
* macOS 10.10+
* tvOS 10.0+
* Swift 5

<a id="installation"></a>
## Installation

<a id="carthage"></a>
### Carthage
```
github "bluejeans/SwiftMockObject" == 0.1.0
```

To add the framework to a test target, go to the *Build Phases* for that target (instead of the *General* settings) and drag SwiftMockObject.framework from the Carthage/Build folder to the *Link Binary With Libraries* section. Then follow the rest of [Carthage](https://github.com/Carthage/Carthage) instructions.

<a id="features"></a>
## Features

To determine if SwiftMockObject is the right mocking library for you...

* **Protocol-based:** SwiftMockObject works best with protocols. If you would like to mock/stub classes or create spies, this will be of limited use.
* **Mocks vs. stubs:** SwiftMockObject has one Mock class that supports both stubbing and verification. You only need to create one mock class regardless of whether you are stubbing or mocking.
* **Non-strict mocks:** Instead of using expect/verify, SwiftMockObject lets you assert the number of times a method was called and its arguments after the fact. This means that mocks are not strict and will not fail the test if a method was called that was not previously expected or asserted.
* **Ease of use:** There is some degree of boilerplate involved in defining a mock (see "Creating a mock" below). However, once this is done, using the mock should be simple, flexible, and type-safe (no need to use strings to refer to methods or arguments).

<a id="usage"></a>
## Usage

SwiftMockObject is protocol-based. If you have an object `MainClass` that uses `DependencyClass`, `DependencyClass` should conform to `DependencyProtocol` and `MainClass` should use `DependencyProtocol` instead of `DependencyClass`.

<a id="creating-a-mock"></a>
### Creating a mock

To create a mock for `DependencyProtocol`, create an enum (e.g. `DependencyProtocolMethods`) representing the methods of the protocol, then create a mock class that subclasses `MockObject<DependencyProtocolMethods>` and conforms to `DependencyProtocol`. The mock class can then use `_onMethod()` in its implementation to both track method invocations and arguments for later assertion and to provide stubbing functionality.

#### Example
The functionality in your main target that you want to test:

```swift
protocol DependencyProtocol {
    func withOptional(arg: Int?)
    func withComplex(arg: ComplexArg)
    func withReturn() -> Bool
    func with(name: String, callback: @escaping (Int, String) -> Void)
}

struct ComplexArg {
    let key: String
    let value: Any
}

// Actual implementation of DependencyProtocol elided...

class MainClass {
    private let dependency: DependencyProtocol

    init(dependency: DependencyProtocol) {
        self.dependency = dependency
    }

    func invokeDependencyWithComplexArg(countOf array: [Any]) {
        dependency.withComplex(arg: ComplexArg(key: "count", value: array.count))
    }

    // Other methods that use DependencyProtocol elided...
}
```

Creating the mock in your test target:

```swift
enum DependencyProtocolMethods {
    case withOptionalArg
    case withComplexArg
    case withReturn
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

    func with(name: String, callback: @escaping (Int, String) -> Void) {
        _onMethod(.withMultipleArgsAndCallback, args: name, callback)
    }
}
```

<a id="stubbing"></a>
### Stubbing

You can get a `MethodReference` using `mock.methodReference(.enumCase)`. `MethodReference` supports `setCustomBehavior()` to specify a return value or more complex arbitrary behaviors.

#### Example

```swift
mock.methodReference(.withReturn).setCustomBehaviorToReturn(true)

mock.methodReference(.withOptionalReturn).setCustomBehaviorToReturnNil()

mock.methodReference(.withMultipleArgsAndCallback).setCustomBehavior({ [weak self] args in
    // args is an [Any?] and will need to be cast to the expected type
    guard let name = args[0] as? String else { XCTFail("Missing arg"); return }
    self?.doSomethingWithName(name)
})

mock.methodReference(.withMultipleArgsAndCallback).setCustomBehavior({ args in
    guard let callback = args[1] as? (Int, String) -> Void else { XCTFail("Missing arg"); return }
    callback(1, "hello")
})
```

<a id="asserting-method-calls-and-arguments"></a>
### Asserting method calls and arguments

SwiftMockObject provides an extension of `XCTestCase` that adds `MOAssert()` methods. This allows you to assert that a particular method was called a certain number of times, assert that a particular argument was passed, and get an argument to a method if you need to do something more complex with the argument.

By default the assertions operate on the last time the method was called. If you want a previous invocation, pass a non-nil value for `whichTime`. Assertions are not strict; if you omit assertions the test will not fail.

The argument and time parameters start from 1 (i.e. they are not 0-indexed).

#### Example

```swift
// .withArgs was called 0 times
MOAssertTimesCalled(mock.methodReference(.withArg), 0)

// .withArg was called at least once
// For the most recent invocation, the first argument was equal to 42
MOAssertArgumentEquals(mock.methodReference(.withArg), 1, 42)

// .withOptionalArg was called at least once
// For the most recent invocation, the first argument was nil
MOAssertArgumentNil(mock.methodReference(.withOptionalArg), 1)

// .withArg was called at least 3 times
// For the third invocation, the first argument was equal to 42
MOAssertArgumentEquals(mock.methodReference(.withOptionalArg), 1, 3, 42)

// .withComplexArg was called at least once
// Returns the first argument of the most recent invocation
// You may want to do this if you need to do something with the argument,
// e.g. if the argument does not conform to Equatable and you need to
// do a more complex check.
let actualArg: ComplexArg = MOAssertAndGetArgument(mock.methodReference(.withComplexArg), 1)!
XCTAssertEqual(actualArg.key, "count")
XCTAssertEqual(actualArg.value as? Int, 3)
```

<a id="more-examples"></a>
### More examples

See the [TestAbstractExample.swift](./ExampleTests/TestAbstractExample.swift) for a full test case based on the examples above.

More examples can be found in the [Example](./Example) project and its unit tests in [ExampleTests](./ExampleTests).

<a id="credits"></a>
## Credits

* [@abrindam](https://github.com/abrindam)
* [@onelittlefish](https://github.com/onelittlefish)
* [@bluejeans](https://github.com/bluejeans)

<a id="license"></a>
## License

See [LICENSE](./LICENSE)
