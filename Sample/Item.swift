//
//  Item.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 19/10/22.
//

import Foundation


public struct Item: Codable, Identifiable, RawRepresentable {
    public var id: String
    public var rawValue: String
   
    public init( rawValue: String  ) {
        self.id = UUID().uuidString
        self.rawValue = rawValue
    }
}


extension String.StringInterpolation {
    mutating func appendInterpolation(_ item: Item) {
        appendInterpolation(item.rawValue)
    }
}
