//
//  ContentView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI
import LineEditor

struct ContentView: View {
    
    @State var items = [
        Item( rawValue: "line1" ),
        Item( rawValue:"line2"),
        Item( rawValue:"line3"),
        Item( rawValue:"line1"),
        Item( rawValue:"line2"),
        Item( rawValue:"line3"),
        Item( rawValue:"line1"),
        Item( rawValue:"line2"),
        Item( rawValue:"line3"),
        Item( rawValue:"line1"),
        Item( rawValue:"line2"),
        Item( rawValue:"line3"),
        Item( rawValue:"line1"),
        Item( rawValue:"line2"),
        Item( rawValue:"line3"),
        Item( rawValue:"line1"),
        Item( rawValue:"line2"),
        Item( rawValue:"line3"),
        Item( rawValue:"line1"),
        Item( rawValue:"line2"),
        Item( rawValue:"line_last")
    ]
    
    
    var body: some View {
        
        //NavigationStack {
            LineEditorView<Item, SimpleLineEditorKeyboard>(items: $items)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Line Editor")
                .toolbar {
                    ToolbarItem(placement:.navigationBarTrailing) {
                        EditButton()
                    }
                }
        //}
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
