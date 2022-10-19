//
//  LineEditorCustomKeybaord.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 19/10/22.
//

import SwiftUI

struct LineEditorCustomKeyboard: View {
    typealias Symbol = String
    
    var onHide:() -> Void
    var onPressSymbol: (Symbol) -> Void
    
    var body : some View{
        
        ZStack(alignment: .topLeading) {
            
            TabView {
                ContentView( [ [ "A", "B", "C", "D" ] ] )
                    .tabItem {
                        Label( "Key1", systemImage: "list.dash")
                            .labelStyle(.titleOnly)
                    }
                ContentView( [ [ "A", "B", "C", "D" ] ] )
                    .tabItem {
                        Label( "Key2", systemImage: "square.and.pencil")
                            .labelStyle(.titleOnly)
                    }
                ContentView( [ [ "A", "B", "C", "D" ] ] )
                    .tabItem {
                        Label( "Key3", systemImage: "square.and.pencil")
                            .labelStyle(.titleOnly)
                    }
            }
            .frame(maxWidth: .infinity )
            .background(Color.gray.opacity(0.1))
            .cornerRadius(25)
            
            Button(action: onHide) {
                Image(systemName: "xmark").foregroundColor(.black)
            }
            .padding()
                
        }
    }
    
    func ContentView( _ group: [[Symbol]] ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack(spacing: 15){
                
                ForEach( Array(group.enumerated()), id: \.offset) { rowIndex, i in
                    
                    HStack(spacing: 10) {
                        
                        ForEach( Array(i.enumerated()), id: \.offset ) { cellIndex, symbol in
                            
                            Button {
                                
                                onPressSymbol(symbol)
                                
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


extension LineEditorCustomKeyboard {
    
    func ButtonLabel( for group: [[Symbol]], row: Int, cell: Int, symbol: Symbol ) -> some View  {
        Text(symbol)
            .font(.system(size: 16).bold())
    }
}

struct LineEditorCustomKeybaord_Previews: PreviewProvider {
    static var previews: some View {
        LineEditorCustomKeyboard( onHide: {  }, onPressSymbol: { _ in } )
    }
}
