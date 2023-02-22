//
//  SwiftUIView.swift
//  
//
//  Created by Bartolomeo Sorrentino on 19/02/23.
//

import SwiftUI
import UIKit

// [Figure out size of UILabel based on String in Swift](https://stackoverflow.com/a/30450559/521197)
private extension String {

    func size(font: UIFont) -> CGSize {
        let infinity:CGFloat = .infinity
        let constraintRect = CGSize(width: infinity,
                                    height: infinity)
        let boundingRect =  self.boundingRect(with: constraintRect,
                                              options: .usesLineFragmentOrigin,
                                              attributes: [.font: font],
                                              context: nil)
        return boundingRect.size
    }
}


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
    
    var text:String {
        textElements
            .reduce("") { (partialResult, data) in
                partialResult + "\(data.value) "
            }
    }
    
    lazy var regex:NSRegularExpression? = {
        let line_begin_keywords = "(?i)^\\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|enum|abstract|class|abstract\\s+class|state|autonumber(\\s+stop|resume)?|activate|deactivate|destroy|newpage|alt|else|opt|loop|par|break|critical|group|box|rectangle|namespace|partition|archimate|sprite|left|right|side|top|bottom)\\b"

        return try? NSRegularExpression(pattern: line_begin_keywords)
    }()
    
    func match( _ text: String ) -> Bool {
        
        text.components( separatedBy: " ").first { string in
            regex?.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) != nil
        } != nil
    
    }
    
    private func internalParse( _ text: String ) -> Array<SyntaxTextData> {
        
        let strings = text.components( separatedBy: " ")
        
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

            if let _ = regex?.firstMatch(in: string, range: NSRange(string.startIndex..., in: string))  {
            // if(  string.firstMatch(of: line_begin_keywords) != nil ) {
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

    func parse( from text: String ) {
        textElements = internalParse( text )
    }
}


@MainActor public protocol UISyntaxTextViewDelegate : NSObjectProtocol {
    
    func syntaxTextDidChangeText( replacementString string: String)

}

class UISyntaxTextView: UIView {
    
    class TagView: UIStackView {

        var padding = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 5)
        var font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .regular)
        var onDelete:(() -> Void)?
        
        private var label = UILabel()
        private var button = UIButton()
        
        var text:String? {
            get {
                label.text
            }
            set {
                label.text = newValue
            }
            
        }
        
        init( ) {
            super.init( frame: .zero )
            self.isUserInteractionEnabled = false
            self.distribution = .fillProportionally
            self.alignment = .center
            self.isLayoutMarginsRelativeArrangement = true
            self.layoutMargins = padding
            self.spacing = 0
            self.isUserInteractionEnabled = true

            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = font

            self.addArrangedSubview(label)
            
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(systemName: "x.circle"), for: .normal)
            
            let delete_action = UIAction( title:"delete" ) { [weak self] _ in
                self?.onDelete?()
            }
            button.addAction( delete_action , for: .touchDown)

            self.addArrangedSubview(button)
            
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
              
        override func sizeToFit() {
            button.sizeToFit()
            
            var size = CGSize( width: button.frame.size.width + padding.left + padding.right,
                               height: button.frame.size.height )
            
            print( Self.self, #function, button.frame.size, label.frame.size)
            
            if let text = label.text {
                
                let label_size =  text.size(font: font)
                size.width += label_size.width * 1.1
                size.height = max(label_size.height, size.height )

            }
            
            size.height += padding.top + padding.bottom
            size.width += self.spacing
            
            self.frame.size = size
        }
    
        @objc func onRemove() {
            
        }
    }
    
    private var syntaxTextObject  = SyntaxTextObject()
    
    var padding:UIEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
    
    var text: String  = "" {
        
        didSet {
            print( Self.self, #function, "didSet ")
            internalInit( from: text, startingAt: 0 )
            sizeToFit()
        }
    }

    var delegate:UISyntaxTextViewDelegate?
    
    
    private func initTagView( token: String, withIndex index: Int ) -> UIView {
        let subview = TagView()
        subview.tag = index
        subview.layer.borderColor = UIColor.blue.cgColor
        subview.layer.borderWidth = 2
        subview.layer.cornerRadius = 12
        subview.text = token
        subview.onDelete = { [weak self] in
            self?.syntaxTextObject.removeElement(at: index)
            self?.reload(startingAt: 0 )
        }
        
        subview.sizeToFit()
        
        return subview
    }

    private func initTextField( text: String?, withIndex index: Int ) -> UITextField {
        
        let subview = UITextField()
        subview.tag = index
        subview.delegate = self
        subview.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular)
//        subview.layer.borderColor = UIColor.black.cgColor
//        subview.layer.borderWidth = 2
        subview.text = text
        
        return subview
        
    }

    private func internalLayoutSubviews() {
        
        let initValue:UIView? = nil
        
        let _ = subviews.reduce( initValue ) { partialResult, view in

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
        
        let new_size = subviews.reduce( CGSize.zero ) { partialResult, view in
            
            var result = CGSize()
            result.height =  max( partialResult.height, view.intrinsicContentSize.height )
            result.width = partialResult.width + view.intrinsicContentSize.width
            return result
           
        }
        
        print( Self.self, #function, "new size: \(new_size)")

        self.frame.size = new_size

    }
    
    private func reload( startingAt start_index: Int ) {
        guard start_index >= 0 && start_index < syntaxTextObject.textElements.endIndex else {
            return
        }

        print( Self.self, #function )
        
        let syntaxTextSubviews = subviews[start_index..<subviews.endIndex]
        
        syntaxTextSubviews.forEach {
            $0.removeFromSuperview()
        }

        let tokens =  syntaxTextObject.textElements.indices
        
        tokens.indices[start_index..<tokens.endIndex].forEach { index in
            
            if let token = syntaxTextObject.getToken( at: index ) {
                
                let subview = initTagView(token: token, withIndex: index )
                                
                self.addSubview(subview)
                
            }
            else {
                
                let subview = initTextField( text: syntaxTextObject.getText( at: index), withIndex: index )
                
                subview.translatesAutoresizingMaskIntoConstraints = false
                
                self.addSubview(subview)
                
                subview.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
            }
        }

    }
    private func internalInit( from text: String, startingAt start_index: Int  ) {
        
        print( Self.self, #function )

        syntaxTextObject.parse( from: text )
        
        reload(startingAt: start_index )
    }
    
   
    override func layoutSubviews() {
        super.layoutSubviews()
        print( Self.self, #function, self.frame.size)
        
        internalLayoutSubviews()

    }

}

extension UISyntaxTextView: UITextFieldDelegate {

    func findFirstTextField( from index: Int ) -> UITextField? {
    
        for i in index..<subviews.endIndex {
            
            if let result = subviews[i] as? UITextField {
                return result
            }
        }
        
        return nil
    }

    func findFirstTextFieldBackward( from index: Int ) -> UITextField? {
        
        for i in stride(from: index, to: 0, by: -1)  {
            
            if let result = subviews[i] as? UITextField {
                return result
            }
        }
        
        return nil
    }

    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
                
        print( Self.self, #function )
        
        guard let previousText = textField.text, let rangeInText = Range(range, in: previousText) else {
            return true
        }
            
        let updatedText = previousText.replacingCharacters(in: rangeInText, with: string)
            
        let index = textField.tag
                
        syntaxTextObject.setText( updatedText, at: index)

        let text = syntaxTextObject.text
        
        print( Self.self, #function, updatedText  )
        
        if let _ =  string.rangeOfCharacter(from: CharacterSet.whitespaces) {

            if syntaxTextObject.match(updatedText) {

                internalInit( from: text, startingAt: index)
                
                if let nextTextField = findFirstTextField(from: index+1 ){
                
                    nextTextField.becomeFirstResponder()
                    
                    // [getting and setting the cursor position](https://www.programming-books.io/essential/ios/getting-and-setting-the-cursor-position-7729477acddf4aaa8539261a52c5d5ff#2fbd8912-9cba-4666-b1a2-6422911ebd86)

                    let cursor_position = nextTextField.beginningOfDocument
                    nextTextField.selectedTextRange = nextTextField.textRange( from: cursor_position, to: cursor_position)
                    
                }

            }
            
        }

        delegate?.syntaxTextDidChangeText( replacementString: text )

        return true
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

extension UISyntaxTextField: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
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
