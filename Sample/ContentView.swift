//
//  ContentView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI
import LineEditor

struct ContentView: View {
    
    @State var fontSize:CGFloat = 15
    
    @State var items = [
        Item( rawValue:"line_first"),
        Item( rawValue: "line01" ),
        Item( rawValue:"line02"),
        Item( rawValue:"line03"),
        Item( rawValue:"line04"),
        Item( rawValue:"line05"),
        Item( rawValue:"line06"),
        Item( rawValue:"line07"),
        Item( rawValue:"line08"),
        Item( rawValue:"line09"),
        Item( rawValue:"line10"),
        Item( rawValue:"line11"),
        Item( rawValue:"line13"),
        Item( rawValue:"line14"),
        Item( rawValue:"line15"),
        Item( rawValue:"line16"),
        Item( rawValue:"line17"),
        Item( rawValue:"line18"),
        Item( rawValue:"line19"),
        Item( rawValue:"line20"),
        Item( rawValue:"line21"),
        Item( rawValue:"line_last")
    ]
    
    
    var body: some View {
        
        //NavigationStack {
        NavigationView {

            LineEditorView<Item, SimpleLineEditorKeyboard>(items: $items, fontSize: $fontSize)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Line Editor")
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        HStack( spacing: 0 ) {
                            Button( action: {
                                fontSize += 1
                            } ) {
                                Image( systemName: "textformat.size.larger")
                            }
                            Button( action: {
                                fontSize -= 1
                            } ) {
                                Image( systemName: "textformat.size.smaller")
                            }
                        }
                    }
                    ToolbarItem(placement:.navigationBarTrailing) {
                        EditButton()
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onChange(of: items ) {newValue in
            newValue.enumerated().forEach { ( index, item ) in
                print( "\(index)) \(item.rawValue)" )
            }
            
            
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
