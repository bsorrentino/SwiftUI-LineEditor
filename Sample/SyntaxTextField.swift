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
    
    class PaddingLabel: UILabel {

        var padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)

        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.inset(by: padding))
        }

        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            return CGSize(width: size.width + padding.left + padding.right,
                          height: size.height + padding.top + padding.bottom)
        }
    
    }
    
    static let TAG = 100
    
    private var syntaxTextObject  = SyntaxTextObject()
    
    var padding:UIEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
    
    var text: String  = "" {
        
        didSet {
            print( Self.self, #function, "didSet ")
            internalInit()
            sizeToFit()
        }
    }
        
    private var calc_site_on_layout_subviews = true
    
    private func initTextView( token: String ) -> UIView {
        let subview = PaddingLabel()
        subview.tag = Self.TAG
        subview.layer.borderColor = UIColor.blue.cgColor
        subview.layer.borderWidth = 2
        subview.layer.cornerRadius = 12
        subview.text = token
        subview.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)
//            subview.translatesAutoresizingMaskIntoConstraints = false
        subview.isUserInteractionEnabled = false
//        subview.sizeToFit()
        subview.frame.size = subview.intrinsicContentSize
        return subview
    }

    private func initTextField( text: String? ) -> UITextField {
        
        let subview = UITextField()
        subview.tag = UISyntaxTextView.TAG
//        subview.delegate = self
        subview.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular)
//            subview.layer.borderColor = UIColor.black.cgColor
//            subview.layer.borderWidth = 2
        subview.text = text
        
        return subview
        
    }

    private var syntaxTextSubviews:[UIView] {
        subviews.filter {
            $0.tag == Self.TAG
        }
    }
    
    private func internalLayoutSubviews() {
        
        let initValue:UIView? = nil
        
        let _ = syntaxTextSubviews.reduce( initValue ) { partialResult, view in

            view.frame.size.height = self.frame.size.height

            if let prev = partialResult {
                let width = padding.left + prev.frame.size.width + padding.right
                view.frame.origin.x = prev.frame.origin.x + width

            }

            return view
        }

    }
    override func sizeToFit() {
        super.sizeToFit()
        
        let new_size = syntaxTextSubviews.reduce( CGSize.zero ) { partialResult, view in
            
            var result = CGSize()
            result.height =  max( partialResult.height, view.intrinsicContentSize.height )
            result.width = partialResult.width + view.intrinsicContentSize.width
            return result
           
        }
        
        print( Self.self, #function, "new size: \(new_size)")

        self.frame.size = new_size

    }
    
    private func internalInit( ) {
        
        print( Self.self, #function )

        syntaxTextSubviews.forEach {
            $0.removeFromSuperview()
        }

        let tokens =  syntaxTextObject.tokens( from: text )
        
        tokens.forEach { index in
            
            if let token = syntaxTextObject.getToken( at: index ) {
                
                let subview = initTextView(token: token )
                                
                self.addSubview(subview)
                
            }
            else {
                
                let subview = initTextField( text: syntaxTextObject.getText( at: index) )
                
                subview.translatesAutoresizingMaskIntoConstraints = false
                
                self.addSubview(subview)
                
                subview.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
            }
        }
        
    }
    
   
    override func layoutSubviews() {
        super.layoutSubviews()
        print( Self.self, #function, self.frame.size)
        
        internalLayoutSubviews()

    }

}

class UISyntaxTextField: UIViewController {
    
    let scrollView = UIScrollView()
    let contentView = UISyntaxTextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupContentView()
    }
    
    func setupContentView() {
        
        contentView.sizeToFit()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(contentView)
        
        contentView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true

    }
    
    func setupScrollView() {
        
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

//        scrollView.layer.borderColor = UIColor.red.cgColor
//        scrollView.layer.borderWidth = 2
        
        view.addSubview(scrollView)
        
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
    }
    
    override func viewDidLayoutSubviews() {
        contentView.sizeToFit()
        super.viewDidLayoutSubviews()
        print( Self.self, #function, contentView.frame.size)
        // Do any additional setup after loading the view
        let size = CGSize( width: contentView.frame.size.width + 50, height: contentView.frame.size.height )
        scrollView.contentSize = size
    }
    
}

extension UISyntaxTextField: UIScrollViewDelegate {
    
    // [Restrict scrolling direction](https://riptutorial.com/ios/example/31978/restrict-scrolling-direction)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // only horizontal scroll allowed
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
        
    }
}

struct SyntaxTextField : UIViewControllerRepresentable {
    
    
    typealias UIViewControllerType = UISyntaxTextField
    
    typealias UIViewType = UISyntaxTextField
    
    var text: String
    var size: CGSize
    
    func makeUIViewController(context: Context) -> UISyntaxTextField {
        UISyntaxTextField()
    }
    
    func updateUIViewController(_ uiViewController: UISyntaxTextField, context: Context) {
        uiViewController.contentView.text = text
    }
    

}

struct SyntaxTextField_Previews: PreviewProvider {
    static var previews: some View {
            GeometryReader{ proxy in
                SyntaxTextField( text: "participant p1 xxxxxxxx participant xxxxxxxx", size: proxy.size )
            
            }
            .frame( width: .infinity, height: 34)
    }
}
