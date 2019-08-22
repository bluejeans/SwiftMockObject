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
import SwiftMockObject

protocol ExampleProtocol {
    func simple()
    func with(arg: Int)
    func withOptional(arg: Int?)
    func withReturn() -> Bool
    func withOptionalReturn() -> String?
    func with(name: String, callback: @escaping (Int, String) -> Void)
    func withReturn(callback: @escaping (Int, String) -> Void) -> Bool
}

enum ExampleProtocolMethods {
    case simple
    case withArg
    case withOptionalArg
    case withReturn
    case withOptionalReturn
    case withMultipleArgsAndCallback
    case withReturnAndCallback
}

class MockExampleProtocol: MockObject<ExampleProtocolMethods>, ExampleProtocol {
    func simple() {
        _onMethod(.simple)
    }

    func with(arg: Int) {
        _onMethod(.withArg, args: arg)
    }

    func withOptional(arg: Int?) {
        _onMethod(.withOptionalArg, args: arg)
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

    func withReturn(callback: @escaping (Int, String) -> Void) -> Bool {
        return _onMethod(.withReturnAndCallback, defaultReturn: true, args: callback)
    }
}
