//
//  LineEditorApp.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI
import LineEditor

@main
struct LineEditorApp: App {
    let line_begin_keywords = "(?i)^\\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|class|state|autonumber|group|box|rectangle|namespace|partition|archimate|sprite)\\b"

    var body: some Scene {
        WindowGroup {
            TabView {
               
                StandardEditorView()
                    .tabItem {
                        Label("Standard Line Editor", image: "")
                    }

                SyntaxEditorView()
                    .tabItem {
                        Label("Syntax Line Editor", image: "")
                    }

                VStack {
                    Spacer( minLength: 200)
                    SyntaxTextField( text: "participant participant xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxx",
                                     patterns:  [
                                         
                                         SyntaxtTextToken( pattern: line_begin_keywords,
                                                           tokenFactory: {  UITagView() } )
                                     ])
                    Spacer()

                }
                .tabItem {
                    Label("SyntaxTextField", image: "")
                }
            }
        }
    }
}
