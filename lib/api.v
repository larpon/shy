// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module lib

// This is one of the keys that makes it possible to
// expand Shy with completely new backends over time ... hopefully :)
//
// You can use embedding in your custom API struct:
// struct MyAPI {
//     ShyAPI
// }
// pub fn (a MyAPI) init(...)! { ... }
// etc.
// ... then redefine, call or overwrite the methods you need
// ... and then change `ShyAPI` in the `API` struct below to the
// name of the new custom API implementation e.g. "MyAPI"
@[shy: 'api']
struct API {
	ShyAPI // shy:api
}
