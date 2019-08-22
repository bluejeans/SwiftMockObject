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

protocol CatProtocol {
    var isFull: Bool { get }
    func feed(times: Int)
    func giveTreat()
    func giveToy() -> Bool
    func call(name: String, response: @escaping (_ didRespond: Bool) -> Void)
}

class Cat: CatProtocol {
    private(set) var isFull = false

    func feed(times: Int) {
        isFull = times > 10
    }

    func giveTreat() {
        // Do nothing
    }

    func giveToy() -> Bool {
        let toyAccepted = Bool.random()
        return toyAccepted
    }

    func call(name: String, response: @escaping (_ didRespond: Bool) -> Void) {
        DispatchQueue.main.async {
            let didRespond = Bool.random()
            response(didRespond)
        }
    }
}

class Human {
    private let cat: CatProtocol
    private(set) var isHappy = false

    init(cat: CatProtocol) {
        self.cat = cat
    }

    func wakeUp(isFeelingGenerous: Bool) {
        if isFeelingGenerous {
            cat.feed(times: 5)
            cat.giveTreat()
        } else {
            cat.feed(times: 1)
        }
    }

    func comeHome() {
        cat.call(name: "Socks", response: { [weak self] didRespond in
            guard let strongSelf = self else { return }
            if didRespond {
                strongSelf.isHappy = strongSelf.cat.giveToy()
            }
        })
    }
}
