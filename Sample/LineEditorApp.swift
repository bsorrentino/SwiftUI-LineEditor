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
            
            VStack(alignment: .center) {
                SyntaxTextField( text: "participant p1 xxxxxxxx participant xxxxxxxx")
                    
            }
            .frame( height: 50)
        }
    }
}
