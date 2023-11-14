// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Factory to create partner adapters from their class names.
protocol PartnerAdapterFactory {
    func adapters(fromClassNames classNames: Set<String>) -> [(PartnerAdapter, MutablePartnerAdapterStorage)]
}

struct ContainerPartnerAdapterFactory: PartnerAdapterFactory {
    
    /// Uses reflection to dynamically access and instantiate partner adapter objects from their class name.
    func adapters(fromClassNames classNames: Set<String>) -> [(PartnerAdapter, MutablePartnerAdapterStorage)] {
        classNames.compactMap {
            let storage = MutablePartnerAdapterStorage()
            let adapter = (NSClassFromString($0) as? PartnerAdapter.Type)?.init(storage: storage)
            if let adapter = adapter {
                return (adapter, storage)
            } else {
                return nil
            }
        }
    }
}
