//
//  ContentView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI
import LineEditor

class Model : ObservableObject {
    
    @Published var items = (0...50).map { Item( rawValue: "line\($0)" ) }
//    @Published var items = (0...2).map { Item( rawValue: "line\($0)" ) }
}

struct ContentView: View {
    
    @State var fontSize:CGFloat = 15
    @State var showLine:Bool = true

    @StateObject var model = Model()
    
    
    var body: some View {
        
        //NavigationStack {
        NavigationView {

            LineEditorView<Item, SimpleLineEditorKeyboard>(items: $model.items, fontSize: $fontSize, showLine: $showLine)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Line Editor")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        fontSizeView()
                        Button( action: { showLine.toggle() } ) {
                            Image( systemName: "list.number")
                        }
                    }
                    ToolbarItem(placement:.navigationBarTrailing) {
                        EditButton()
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: model.items ) {newValue in
            
//            print( "model.count: \(newValue.count)")
            
            newValue.enumerated().forEach { ( index, item ) in
                print( "\(index)) \(item.rawValue)" )
            }
            
            
        }
        
    }
    
    func fontSizeView() -> some View {
        HStack( spacing: 2 ) {
            Spacer()
            Button( action: { fontSize += 1 } ) {
                Image( systemName: "textformat.size.larger")
            }
            Divider().background(Color.blue)
            Spacer()
            Button( action: { fontSize -= 1} ) {
                Image( systemName: "textformat.size.smaller")
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.blue, lineWidth: 1)
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
