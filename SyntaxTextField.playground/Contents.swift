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
    
    func evaluate() -> String {
        textElements
            .reduce("") { partialResult, data in
                    partialResult + "\(data) "
            }
        
    }
    
    func tokens( from text: String ) -> Range<Int> {
        
        textElements = text.components(separatedBy: " ")
            .enumerated()
            .filter { _, element in !element.isEmpty }
            .map { _, element in
                SyntaxTextData( token: element, trailingText: "" )
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
            Text( syntaxTextObject.textElements[index].token )
                .padding( 7 )
                .background(.red)
//                .cornerRadius(15)
                .clipShape(Capsule())
            TextField( "", text: $text , onEditingChanged: { editing in
                if editing {
                    syntaxTextObject.textElements[index].trailingText = text
                }
                
            }, onCommit: {
                syntaxTextObject.textElements[index].trailingText = text
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
    @State var text = "participant Test as p1"
    var body: some View {
        SyntaxTextField( text: $text )
            .onChange(of: text ) { newValue in
                print( "onChange: \(newValue)" )
            }
            .frame(minWidth: 1000, alignment: .center)
    }
}

PlaygroundPage.current.setLiveView(ContentView())
