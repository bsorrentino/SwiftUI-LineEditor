//: A UIKit based Playground for presenting user interface
  
import SwiftUI
import PlaygroundSupport


class SyntaxText : ObservableObject {
    @Published var textElements: Array<String> = []
    
    func tokens( text: String ) -> Array<String> {
        text.components(separatedBy: " ")
    }
}


struct SyntaxTextField : View {
    
    @Binding var text: String
    @StateObject var syntaxText  = SyntaxText()
    @State private var trailingText: String = ""
    @State private var leadingText: String = ""
    var body: some View {
        
        ScrollView( .horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                TextField( "", text: $leadingText )
                ForEach( text.components(separatedBy: " "), id: \.self ) {
                    Text( $0)
                        .padding( 7 )
                        .background(.red)
                    //.cornerRadius(15)
                        .clipShape(Capsule())
                }
                TextField( "", text: $trailingText )
            }
        }
    }

    
}


struct ContentView: View {
    @State var text = "participant Test as p1"
    var body: some View {
        SyntaxTextField( text: $text )
    }
}

PlaygroundPage.current.setLiveView(ContentView())
