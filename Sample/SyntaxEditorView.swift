//
//  SyntaxLineEditorView.swift
//  LineEditorSample
//
//  Created by Bartolomeo Sorrentino on 05/03/23.
//

import SwiftUI
import LineEditor


class CustomLineEditorTextFieldVC : LineEditorSyntaxTextFieldVC {
    
    static let line_begin_keywords = "(?i)^\\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|class|state|autonumber|group|box|rectangle|namespace|partition|archimate|sprite)\\b"

    static let tokens = [
        SyntaxtTextToken( pattern: line_begin_keywords,
                          tokenFactory: {  UITagView() } )
    ]
    
    override func viewDidLoad() {
        
        self.patterns = Self.tokens
        
        super.viewDidLoad()
    }
}

struct SyntaxEditorView : View {
    
    @State private var selectedTab = "Key2"
    
    @State var fontSize:CGFloat = 15
    @State var showLine:Bool = true

    @StateObject var model = Model()
    
    
    var body: some View {
        
        //NavigationStack {
        NavigationView {

            LineEditorView<KeyboardSymbol, CustomLineEditorTextFieldVC>(text: $model.text, fontSize: $fontSize, showLine: $showLine) {
                onHide, onPressSymbol in
                SimpleLineEditorKeyboard(onHide: onHide, onPressSymbol: onPressSymbol )
                    .environment(\.keyboardSelectedTab, $selectedTab)
                    
            }
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
        .onChange(of: model.text ) {newValue in
            
           print( "model.text: \(newValue)")
            
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

struct SyntaxLineEditorView_Previews: PreviewProvider {
    static var previews: some View {
        SyntaxEditorView()
    }
}
