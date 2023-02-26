//
//  SwiftUIView.swift
//  
//
//  Created by Bartolomeo Sorrentino on 19/02/23.
//

import SwiftUI
import LineEditor

struct SyntaxTextField : UIViewControllerRepresentable {
        
    var text: String
    var patterns:Array<SyntaxtTextToken>
    
    func makeUIViewController(context: Context) -> LineEditorSyntaxTextFieldVC {
        let controller = LineEditorSyntaxTextFieldVC()
        
        controller.patterns = patterns
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: LineEditorSyntaxTextFieldVC, context: Context) {
        uiViewController.contentView.text = text
    }
    

}

struct SyntaxTextField_Previews: PreviewProvider {
    
    static let line_begin_keywords = "(?i)^\\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|class|state|autonumber|group|box|rectangle|namespace|partition|archimate|sprite)\\b"
 
    static var previews: some View {
        
        SyntaxTextField(
            text: "participant p1 xxxxxxxx participant xxxxxxxx",
            patterns:  [
                
                SyntaxtTextToken( pattern: line_begin_keywords,
                                  tokenFactory: {  UITagView() },
                                  skipWhen: { index, _ in index > 0 }
                                )
            ]

        )
        .frame( width: .infinity, height: 34)
    }
}
