//
//  ContentView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        
        NavigationStack {
            LineEditorView()
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("Line Editor")
                .toolbar {
                    ToolbarItem(placement:.navigationBarTrailing) {
                        EditButton()
//                        Button( action: {
//                            
//                        }, label: {
//                            Label( "Edit", systemImage: "pencil.circle.fill")
//                                .labelStyle(.titleAndIcon)
//                        })
                    }
                }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
