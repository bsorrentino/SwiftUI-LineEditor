//
//  SwiftUIView.swift
//  
//
//  Created by Bartolomeo Sorrentino on 19/02/23.
//

import SwiftUI
import UIKit

struct SyntaxTextData {
    var value: String
    var isToken: Bool
}

class SyntaxTextObject {
    var textElements: Array<SyntaxTextData> = []

    func setText( _ text: String, at index: Int ) {
        guard index < textElements.endIndex else { return }
        guard !textElements[ index ].isToken else { return }
        
        textElements[ index ].value = text
    }
    
    func getText( at index: Int ) -> String? {
        guard index < textElements.endIndex else { return nil }
        guard !textElements[ index ].isToken else { return nil }

        return textElements[ index ].value
    }

    func getToken( at index: Int ) -> String? {
        guard index < textElements.endIndex else { return nil  }
        let e = textElements[ index ]
        guard e.isToken else { return nil }
        return e.value
    }

    func removeElement( at index: Int ) {
        guard index < textElements.endIndex else { return }
        textElements.remove(at: index)
    }
    
    func evaluate() -> String {
        textElements.forEach { data in
            print( "{ value: \(data.value), isToken: \(data.isToken) }" )
        }
        return textElements
            .reduce("") { (partialResult, data) in
                partialResult + "\(data.value) "
            }
        
    }

    let line_begin_keywords = "(?i)^\\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|enum|abstract|class|abstract\\s+class|state|autonumber(\\s+stop|resume)?|activate|deactivate|destroy|newpage|alt|else|opt|loop|par|break|critical|group|box|rectangle|namespace|partition|archimate|sprite|left|right|side|top|bottom)\\b"

    func parse( strings: Array<String> ) -> Array<SyntaxTextData> {
        
        var result = Array<SyntaxTextData>()

        var currentNonTokenItem:SyntaxTextData?

        let merge = { ( left: SyntaxTextData?, right: String ) in
            
            guard let left else {
                return SyntaxTextData( value: right, isToken: false)
            }
            
            if left.isToken {
                throw NSError( domain: "value '\(left.value)' is a token", code: -1)
            }
            
            return SyntaxTextData( value: "\(left.value) \(right)", isToken: false)

        }
        
        strings.forEach { string in

            if let regex = try? NSRegularExpression(pattern: line_begin_keywords),
                let _ = regex.firstMatch(in: string, range: NSRange(string.startIndex..., in: string))  {
            //if(  string.firstMatch(of: line_begin_keywords) != nil ) {
                if let currentItem = currentNonTokenItem {
                    result.append( currentItem )
                    currentNonTokenItem = nil
                }
                result.append( SyntaxTextData( value: string, isToken: true ) )
            }
            else {
                currentNonTokenItem =  try? merge( currentNonTokenItem, string )
            }

        }
        if let currentNonTokenItem {
            result.append( currentNonTokenItem )
        }
        else if result.isEmpty {
            result.append(  SyntaxTextData( value: "", isToken: false ) )
        }
        return result

    }

    func tokens( from text: String ) -> Range<Int> {
        
        textElements = parse( strings: text.components( separatedBy: " ") )
        return textElements.indices
    }
}

class UISyntaxTextView: UIView {
    static let TAG = 100
    
    private weak var syntaxTextObject: SyntaxTextObject? = nil
    
    private(set) var index: Int
    
    init( index: Int, syntaxTextObject: SyntaxTextObject ) {
        self.index = index
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        self.tag = UISyntaxTextView.TAG
        self.syntaxTextObject = syntaxTextObject
        
        internalInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented!" )
    }
    
    override var intrinsicContentSize: CGSize {
        
        if let subview = self.subviews.first {
            
            if let field = subview as? UITextField {
                return CGSize( width: max( field.frame.size.width, 15 ),
                               height:   field.frame.size.height )
            }
            return subview.frame.size
        }
        return .zero
    }
    
//    override func sizeThatFits(_ size: CGSize) -> CGSize {
//        print( Self.self, #function, size)
//
//        return super.sizeThatFits(size)
//
//    }
    
    private func internalInit() {
        //guard let syntaxTextObject else { fatalError("syntaxTextObject is not initialized!" ) }
        guard let syntaxTextObject else { return }
        

        let font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .light)
        
        if let token = syntaxTextObject.getToken( at: index ) {
            
            print( Self.self, #function, "add label[\(index)]: \(token)" )
            
            let subview = UITextView()
            subview.layer.borderColor = UIColor.blue.cgColor
            subview.layer.borderWidth = 2
            subview.layer.cornerRadius = 15
            subview.text = token
            subview.font = font
            subview.translatesAutoresizingMaskIntoConstraints = false
            subview.isUserInteractionEnabled = false
            subview.sizeToFit()

            self.addSubview( subview )
            
            //subview.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

        } else {
            
            let subview = UITextField()
            
            subview.font = font
            subview.layer.borderColor = UIColor.black.cgColor
            subview.layer.borderWidth = 2
            if let value = syntaxTextObject.getText( at: index ) {
                print( Self.self, #function, "add field[\(index)]: \(value)" )
                subview.text = value
            }
            subview.translatesAutoresizingMaskIntoConstraints = false
            
            self.addSubview( subview )
            
            subview.widthAnchor.constraint(greaterThanOrEqualToConstant: 15).isActive = true
            subview.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

        }
            
    }
    
}

class UISyntaxTextField: UIScrollView, UITextInputTraits {
    
    private var syntaxTextObject  = SyntaxTextObject()

    
    var text: String  = "" {
        
        didSet {
            
            print( Self.self, #function, "didSet ")
            internalInit()
        }
    }
    
    override init( frame: CGRect ) {
        super.init(frame: frame )
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 2

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func calcLayout() {
        let subviews = subviews.filter {
            $0.tag == UISyntaxTextView.TAG
        }
        
        let max_height = subviews.reduce( 0 ) { partialResult, view in
            max( partialResult, view.intrinsicContentSize.height )
        }
        
        print( Self.self, #function, "max height: \(max_height)")
        
        let initValue:UIView? = nil
        let _ = subviews.reduce(initValue) { partialResult, view in
            
            if let prev = partialResult {
                view.frame.origin.x = prev.frame.origin.x + prev.frame.size.width - 10
            }
            
            view.frame.size.height = max_height
            return view
        }

    }
    
    private func internalInit( ) {
        
        print( Self.self, #function )
                
        print( contentSize )

        subviews.filter {
            $0.tag == UISyntaxTextView.TAG
        }
        .forEach {
            $0.removeFromSuperview()
        }

        let tokens =  syntaxTextObject.tokens( from: text )
        
        tokens.forEach { index in
            
            let view = UISyntaxTextView(index: index, syntaxTextObject: syntaxTextObject )
            
            self.addSubview(view)
            
        }
        
        calcLayout()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print( Self.self, #function)
        
    }
}


struct SyntaxTextField : UIViewRepresentable {
    typealias UIViewType = UISyntaxTextField
    
    var text: String

    func makeUIView(context: Context) -> UISyntaxTextField {
        UISyntaxTextField()
    }
    
    func updateUIView(_ uiView: UISyntaxTextField, context: Context) {
        
        uiView.text = text
    }
    
}

struct SyntaxTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .center) {
            SyntaxTextField( text: "participant p1 xxxxxxxx participant xxxxxxxx")
                
        }
        .frame( height: 50)
    }
}
