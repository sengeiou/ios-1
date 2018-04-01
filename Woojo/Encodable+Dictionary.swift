//
//  Encodable+Dictionary.swift
//  Woojo
//
//  Created by Edouard Goossens on 27/03/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: [.allowFragments])).flatMap { $0 as? [String: Any] }
    }
    
    var array: NSArray? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: [.allowFragments])).flatMap { $0 as? NSArray }
    }
    
    /* var jsonString: String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) else { return nil }
        // print("DATAA", data)
        return String(data: jsonData, encoding: String.Encoding.utf8)
    } */
}
