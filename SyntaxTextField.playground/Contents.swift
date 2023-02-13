//: A UIKit based Playground for presenting user interface
  
import SwiftUI
import PlaygroundSupport


struct SyntaxTextData:  CustomStringConvertible {
    
    var token: String = ""
    var trailingText:String = ""
    
    var description:String {
        (token.isEmpty) ? trailingText : "\(token) \(trailingText)"
    }
    

}

class SyntaxTextObject : ObservableObject {
    var textElements: Array<SyntaxTextData> = []

    

    func setTrailingText( _ text: String, at index: Int ) {
        guard index < textElements.endIndex else { return }
        textElements[ index ].trailingText = text
    }

    func getTrailingToken( at index: Int ) -> String? {
        guard index < textElements.endIndex else { return nil  }
        return textElements[ index ].token
    }

    func removeElement( at index: Int ) {
        guard index < textElements.endIndex else { return }
        textElements.remove(at: index)
    }
    
    func evaluate() -> String {
        textElements
            .reduce("") { partialResult, data in
                    partialResult + "\(data) "
            }
        
    }

    let keywords = /(?i)^\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|enum|abstract|class|abstract\s+class|state|autonumber(\s+stop|resume)?|activate|deactivate|destroy|newpage|alt|else|opt|loop|par|break|critical|group|box|rectangle|namespace|partition|archimate|sprite|left|right|side|top|bottom)\b/

    func match( with text: String ) -> Bool {
        
        return text.firstMatch(of: keywords) != nil
        
    }
    
    func tokens( from text: String ) -> Range<Int> {
        
        textElements = text.components(separatedBy: " ")
            .enumerated()
            .filter { _, element in !element.isEmpty }
            .map { _, element in
                SyntaxTextData( token: element, trailingText: "" )
        }
        if textElements.isEmpty {
            textElements = [ SyntaxTextData( token: "", trailingText: "" )]
        }
        return textElements.indices
    }
}

struct SyntaxTextView : View {
    @EnvironmentObject private var syntaxTextObject: SyntaxTextObject

    var index: Int
    @State var text: String = ""

    var body: some View {
        HStack {
            let token = syntaxTextObject.getTrailingToken( at: index )
            if let token, !token.isEmpty {
                ZStack(alignment: .trailing) {
                    Text( token )
                        .padding( EdgeInsets(top: 7, leading: 7, bottom: 7, trailing: 18))
                        .background(.red)
        //                .cornerRadius(15)
                        .clipShape(Capsule())
                    
                    Button( action: {
                        syntaxTextObject.removeElement(at: index)
                        syntaxTextObject.objectWillChange.send()
                    }) {
                        Image( systemName: "x.circle")
                            .resizable()
                            .frame( width: 13, height: 13)
                    }
                    .padding( .trailing, 3 )
                    
                }
            }
            TextField( "", text: $text , onEditingChanged: { editing in
                if editing {
                    syntaxTextObject.setTrailingText( text, at: index )
                }
                
            }, onCommit: {
                syntaxTextObject.setTrailingText( text, at: index )
                syntaxTextObject.objectWillChange.send()

            })
        }
    }
}

struct SyntaxTextField : View {
    
    @Binding var text: String
    @StateObject var syntaxTextObject  = SyntaxTextObject()
    @State private var theId = 0

    var body: some View {
        
        ScrollView( .horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                
                ForEach( syntaxTextObject.tokens( from: text ), id: \.self ) { index in
                    
                    SyntaxTextView(index: index )
                        .id(index)
                        .environmentObject(syntaxTextObject)
                }
                .id( theId )
            }
            .onReceive(syntaxTextObject.objectWillChange) { _ in
                
                print( "syntaxTextObject changed")
                let newValue = syntaxTextObject.evaluate()
                print( "syntaxTextObject changed [\(newValue)]")

                text = newValue
                theId += 1
            }
        }
    }

    
}


struct ContentView: View {
    @State var text = "token1 token2 token3"
    var body: some View {
        SyntaxTextField( text: $text )
            .border(.red)
            .onChange(of: text ) { newValue in
                print( "onChange: \(newValue)" )
            }
            .frame(minWidth: 500, alignment: .center)
    }
}

PlaygroundPage.current.setLiveView(ContentView())
