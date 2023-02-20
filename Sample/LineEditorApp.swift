//
//  LineEditorApp.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI

@main
struct LineEditorApp: App {
    
    var body: some Scene {
        WindowGroup {
            //ContentView()
            
            GeometryReader{ proxy in
                SyntaxTextField( text: "participant participant xxxxxxxx", size: proxy.size )
                    
            }
            .frame( height: 50)
        }
    }
}
