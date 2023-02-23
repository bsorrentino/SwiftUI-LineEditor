//
//  LineEditorApp.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI

@main
struct LineEditorApp: App {
    let line_begin_keywords = "(?i)^\\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|class|state|autonumber|group|box|rectangle|namespace|partition|archimate|sprite)\\b"

    var body: some Scene {
        WindowGroup {
            //ContentView()
            
            SyntaxTextField( text: "participant participant xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx",
                             patterns:  [
                                 
                                 SyntaxtTextToken( pattern: line_begin_keywords,
                                                   tokenFactory: {  UITagView() } )
                             ]
)
            .frame( width: .infinity, height: 50)
        }
    }
}
