//
//  Item.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 19/10/22.
//

import Foundation


public struct Item: Codable, RawRepresentable, Equatable {
    public var rawValue: String
   
    public init( rawValue: String  ) {
        self.rawValue = rawValue
    }
}


extension String.StringInterpolation {
    mutating func appendInterpolation(_ item: Item) {
        appendInterpolation(item.rawValue)
    }
}
