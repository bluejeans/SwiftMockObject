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

protocol DependencyProtocol {
    func withOptional(arg: Int?)
    func withComplex(arg: ComplexArg)
    func withReturn() -> Bool
    func withOptionalReturn() -> String?
    func with(name: String, callback: @escaping (Int, String) -> Void)
}

struct ComplexArg {
    let key: String
    let value: Any
}

class MainClass {
    private let dependency: DependencyProtocol

    init(dependency: DependencyProtocol) {
        self.dependency = dependency
    }

    func invokeDependency(times: Int) {
        if times < 1 {
            dependency.withOptional(arg: nil)
        } else {
            (1...times).forEach {
                dependency.withOptional(arg: $0)
            }
        }
    }

    func invokeDependencyWithComplexArg(countOf array: [Any]) {
        dependency.withComplex(arg: ComplexArg(key: "count", value: array.count))
    }

    func oppositeOfDependency() -> Bool {
        return !dependency.withReturn()
    }

    func dependencyWithDefaultValue(_ value: String) -> String {
        return dependency.withOptionalReturn() ?? value
    }

    func doSomething(name: String, callback: @escaping (String) -> Void) {
        dependency.with(name: name, callback: { int, string in
            callback("\(int) \(string)")
        })
    }
}
