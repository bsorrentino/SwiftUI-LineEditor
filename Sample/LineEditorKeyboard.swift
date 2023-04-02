//
//  LineEditorCustomKeybaord.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 19/10/22.
//

import SwiftUI
import LineEditor

private struct KeyboardSelectedTab: EnvironmentKey {
    static let defaultValue: Binding<String> = .constant("k1")
}

extension EnvironmentValues {
    var keyboardSelectedTab: Binding<String> {
        get {
            let v = self[KeyboardSelectedTab.self]
            print( "keyboardSelectedTab get = \(v.wrappedValue)")
            return v
            
        }
        set {
            print( "keyboardSelectedTab set = \(newValue.wrappedValue)")
            self[KeyboardSelectedTab.self] = newValue
        }
    }
}

struct KeyboardSymbol : LineEditorKeyboardSymbol {
    
    private var _value:String
    private var _additionalValues:[String]?

    var id: String
    
    var value: String {
        get { _value }
    }

    var additionalValues: [String]? {
        get { _additionalValues }
    }

    init(_ value:String, _ additionalValues: [String]? = nil) {
        self.id = value
        self._value = value
        self._additionalValues = additionalValues
    }
    
}

struct SimpleLineEditorKeyboard: View {
    typealias Symbol = KeyboardSymbol
    
    @Environment(\.keyboardSelectedTab) private var selectedTab
    var onHide:() -> Void
    var onPressSymbol: (Symbol) -> Void
    
    var body : some View{
        
        ZStack(alignment: .topLeading) {
            
            TabView(selection: selectedTab) {
                ContentView( [ [ "A", "B", "C", "D" ] ] )
                    .tabItem {
                        Label( "Key1", systemImage: "list.dash")
                            .labelStyle(.titleOnly)
                    }
                    .tag( "Key1" )
                ContentView( [ [ "A", "B", "C", "D" ] ] )
                    .tabItem {
                        Label( "Key2", systemImage: "square.and.pencil")
                            .labelStyle(.titleOnly)
                    }
                    .tag( "Key2" )
                ContentView( [ [ "A", "B", "C", "D" ] ] )
                    .tabItem {
                        Label( "Key3", systemImage: "square.and.pencil")
                            .labelStyle(.titleOnly)
                    }
                    .tag( "Key3" )
            }
            .frame(maxWidth: .infinity )
            .background(Color.gray.opacity(0.1))
            .cornerRadius(25)
            .padding()
            
            Button(action: onHide) {
                Image(systemName: "xmark").foregroundColor(.black)
            }
            .padding()
                
        }
    }
    
    func ContentView( _ group: [[String]] ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack(spacing: 15){
                
                ForEach( Array(group.enumerated()), id: \.offset) { rowIndex, i in
                    
                    HStack(spacing: 10) {
                        
                        ForEach( Array(i.enumerated()), id: \.offset ) { cellIndex, value in
                            
                            let symbol = Symbol( value, [ "x1", "x2", "x3" ])
                            Button {
                                
                                onPressSymbol( symbol )
                                
                            } label: {
                                
                                ButtonLabel( for: group, row: rowIndex, cell: cellIndex, symbol: symbol )
                                
                            }
                            .buttonStyle( KeyButtonStyle() )
                        }
                    }
                }
            }
            .padding(.top)
        
        }
    }
}

fileprivate struct KeyButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(5)
            .border( .black, width: 1)
            .background( .white )
    }
}


extension SimpleLineEditorKeyboard {
    
    func ButtonLabel( for group: [[String]], row: Int, cell: Int, symbol: Symbol ) -> some View  {
        Text(symbol.value)
            .font(.system(size: 16).bold())
    }
}

struct SimpleLineEditorCustomKeybaord_Previews: PreviewProvider {
    static var previews: some View {
        SimpleLineEditorKeyboard( onHide: {  }, onPressSymbol: { _ in } )
    }
}
