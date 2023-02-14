//: A UIKit based Playground for presenting user interface
  
import SwiftUI
import PlaygroundSupport

struct SyntaxTextData {
    var value: String
    var isToken: Bool
}


class SyntaxTextObject : ObservableObject {
    var textElements: Array<SyntaxTextData> = []

    func setText( _ text: String, at index: Int ) {
        guard index < textElements.endIndex else { return }
        guard !textElements[ index ].isToken else { return }
        
        textElements[ index ].value = text
    }
    
    func getText( at index: Int ) -> String? {
        guard index < textElements.endIndex else { return nil }
        guard !textElements[ index ].isToken else { return nil }

        return textElements[ index ].value
    }

    func getToken( at index: Int ) -> String? {
        guard index < textElements.endIndex else { return nil  }
        let e = textElements[ index ]
        guard e.isToken else { return nil }
        return e.value
    }

    func removeElement( at index: Int ) {
        guard index < textElements.endIndex else { return }
        textElements.remove(at: index)
    }
    
    func evaluate() -> String {
        textElements.forEach { data in
            print( "{ value: \(data.value), isToken: \(data.isToken)" )
        }
        return textElements
            .reduce("") { (partialResult, data) in
                partialResult + "\(data.value) "
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
            .flatMap { _, element in
                [
                    SyntaxTextData( value: element, isToken: true ),
                    SyntaxTextData( value: "", isToken: false ),
                ]
        }
        if textElements.isEmpty {
            textElements = [ SyntaxTextData( value: "", isToken: false )]
        }
        return textElements.indices
    }
}

struct SyntaxTextView : View {
    @EnvironmentObject private var syntaxTextObject: SyntaxTextObject

    private var index: Int
    @State private var text: String = ""

    init( index: Int ) {
        self.index = index
    }
    
    var body: some View {
        HStack {
            let token = syntaxTextObject.getToken( at: index )
            
            if let token {
                
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
            else {
                TextField( "", text: $text , onEditingChanged: { editing in
                    if editing {
                        syntaxTextObject.setText( text, at: index )
                    }
                    
                }, onCommit: {
                    syntaxTextObject.setText( text, at: index )
                    syntaxTextObject.objectWillChange.send()
                    
                })
                .onAppear {
                    if let value = syntaxTextObject.getText( at: index ) {
                        text = value
                    }
                }
                .frame(minWidth: 15)
            }
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
