//: A UIKit based Playground for presenting user interface
  
import PlaygroundSupport
import Combine
import SwiftUI


class Items : ObservableObject {
    
    @Published var value:Array<String>
    
    private var cancellable: AnyCancellable?
    
    init( _ value: Array<String> ) {
        
        self.value = value
        cancellable = self.$value.sink {
            print( "'\($0[0])'" )
        }
    }
}
struct ContentView : View {
    @StateObject var items = Items( (0...50).map { "line\($0)" } )
    @State var text:String = ""
    var body: some View {
        
        TextField("input", text: $text)
            .onSubmit {
                items.value = [text]
            }
    }
        
}
// Present the view controller in the Live View window
PlaygroundPage.current.setLiveView(ContentView())
