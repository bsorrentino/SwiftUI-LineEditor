import UIKit


class SyntaxText {
    
    struct Data {
        var value: String
        var isToken: Bool
    }
}


extension String.StringInterpolation {
    
    mutating func appendInterpolation(_ value: SyntaxText.Data) {
        appendInterpolation( "{value: \"\(value.value)\", isToken:\(value.isToken) }" )
    }
    
}


let keywords = /(?i)^\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|enum|abstract|class|abstract\s+class|state|autonumber(\s+stop|resume)?|activate|deactivate|destroy|newpage|alt|else|opt|loop|par|break|critical|group|box|rectangle|namespace|partition|archimate|sprite|left|right|side|top|bottom)\b/

func match( with text: String ) -> Bool {
    
    return text.firstMatch(of: keywords) != nil
    
}


func evaluate( data: Array<String> ) throws  -> Array<SyntaxText.Data> {
    
    var result = Array<SyntaxText.Data>()

    var currentNonTokenItem:SyntaxText.Data?

    let merge = { ( left: SyntaxText.Data?, right: String ) in
        
        guard let left else {
            return SyntaxText.Data( value: right, isToken: false)
        }
        
        if left.isToken {
            throw NSError( domain: "value '\(left.value)' is a token", code: -1)
        }
        
        return SyntaxText.Data( value: "\(left.value) \(right)", isToken: false)

    }
    
    try data.forEach { item in

        if match( with: item ) {
            if let currentItem = currentNonTokenItem {
                result.append( currentItem )
                currentNonTokenItem = nil
            }
            result.append( SyntaxText.Data( value: item, isToken: true ) )
        }
        else {
            currentNonTokenItem =  try merge( currentNonTokenItem, item )
        }

    }
    
    return result

}

do {
    let result = try evaluate(data:  [
            "participant",
            "value_1",
            "value_2",
            "value_3",
            "box",
        ])
    
    result.forEach { data in print( "\(data)")
        
    }

} catch {
    print( "\(error)")
}


