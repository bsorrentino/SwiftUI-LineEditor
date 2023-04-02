//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport

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

    let line_begin_keywords = /(?i)^\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|enum|abstract|class|abstract\s+class|state|autonumber(\s+stop|resume)?|activate|deactivate|destroy|newpage|alt|else|opt|loop|par|break|critical|group|box|rectangle|namespace|partition|archimate|sprite|left|right|side|top|bottom)\b/

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

            if(  string.firstMatch(of: line_begin_keywords) != nil ) {
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
            print( Self.self, #function )
            
            if let field = subview as? UITextField {
                print( Self.self, #function, "field: \(field.frame)" )
                return CGSize( width: max( field.frame.size.width, 15 ), height: max( field.frame.size.height, 50 ))
            }
            print( Self.self, #function, "label: \(subview.frame)" )
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
            
            subview.heightAnchor.constraint(greaterThanOrEqualToConstant: 34).isActive = true
            subview.widthAnchor.constraint(greaterThanOrEqualToConstant: 15).isActive = true

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
        
        let hstack = UIStackView()
        hstack.axis = .horizontal
        hstack.distribution = .fill
        hstack.alignment = .fill
        hstack.spacing = 2
        hstack.layer.borderColor = UIColor.red.cgColor
        hstack.layer.borderWidth = 1
        hstack.isUserInteractionEnabled = true
        hstack.translatesAutoresizingMaskIntoConstraints = false;
        self.addSubview( hstack )
        
//        hstack.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
//        hstack.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func internalInit( ) {
        
        print( Self.self, #function )
        
        guard let hstack = self.subviews.first as? UIStackView else { return  }
        
        subviews.filter {
            $0.tag == UISyntaxTextView.TAG
        }
        .forEach {
            $0.removeFromSuperview()
        }

        let tokens =  syntaxTextObject.tokens( from: text )
        
        tokens.forEach { index in
            
            let view = UISyntaxTextView(index: index, syntaxTextObject: syntaxTextObject )
            
            hstack.addArrangedSubview(view)
            
        }
    }
    
}


class MyViewController : UIViewController {
    override func loadView() {
        let view = UISyntaxTextField()
        view.frame.size = CGSize(width: 500, height: 50)
        self.view = view
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if let view = self.view as? UISyntaxTextField {
            view.text = "participant participant XXXXXXXXX YYYYYYYYYY"
        }
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
