//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 26/02/23.
//

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

public protocol SyntaxTextView : UIView {
    var text:String? { get set }
    var onDelete:(() -> Void)? { get set }
}
 

public struct SyntaxtTextToken {
    var factory:() -> UIView
    
    var regex:NSRegularExpression?
    
    var skipWhen: (( Int, [String] ) -> Bool )?
    
    public init( pattern: String,
          tokenFactory:@escaping () -> UIView,
          skipWhen: (( Int, [String] ) -> Bool )? = nil )
    {
        
        regex = try? NSRegularExpression(pattern: pattern)
        self.factory = tokenFactory
        self.skipWhen = skipWhen

    }
}

struct SyntaxTextData {
    var value: String
    var isToken: Bool
    var tokenViewFactory:(() -> UIView)?
    
}

class SyntaxTextModel : ObservableObject {
    
    private var textElements: Array<SyntaxTextData> = []

    var patterns:Array<SyntaxtTextToken>?

    func indices( from: Int  ) -> Range<Int> {
        textElements.indices[ from..<textElements.endIndex]
    }
    
    func isValid( index: Int ) -> Bool {
        index >= 0 && index < textElements.endIndex
    }
    
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

    func getToken( at index: Int ) -> (String, (() -> UIView))?  {
        guard index < textElements.endIndex else { return nil  }
        let e = textElements[ index ]
        guard e.isToken else { return nil }
        return ( e.value, e.tokenViewFactory! )
    }

    var text:String {
        textElements
            .reduce("") { (partialResult, data) in
                partialResult + "\(data.value) "
            }
    }
    
    func match( _ text: String ) -> Bool {
        
        text.components( separatedBy: " ").first { string in
            if let _ = patterns?.first(where: { p in
                p.regex?.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) != nil })
            {
                return true
            }
            return false
        } != nil
    
    }
    
    private func internalParse( _ text: String ) -> Array<SyntaxTextData>
    {
        
        let strings = text.components( separatedBy: " ")
        
        var result = Array<SyntaxTextData>()

        var current_non_token_item:SyntaxTextData?

        let merge = { ( left: SyntaxTextData?, right: String ) in
            
            guard let left else {
                return SyntaxTextData( value: right,
                                       isToken: false)
            }
            
            if left.isToken {
                throw NSError( domain: "value '\(left.value)' is a token", code: -1)
            }
            
            return SyntaxTextData( value: "\(left.value) \(right)",
                                   isToken: false)
        }
        
        strings.enumerated().forEach { index, string in

            if let token = patterns?.filter({ p in
                guard let skipWhen =  p.skipWhen else { return true }
                return !skipWhen( index, strings )
            }).first(where: { p in
                    p.regex?.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)) != nil })
            {
                
                if let currentItem = current_non_token_item {
                    result.append( currentItem )
                    current_non_token_item = nil
                }
                
                result.append( SyntaxTextData( value: string,
                                               isToken: true,
                                               tokenViewFactory: token.factory ) )
            }
            else {
                current_non_token_item =  try? merge( current_non_token_item, string )
            }

        }
        if let current_non_token_item {
            result.append( current_non_token_item )
        }
        else if result.isEmpty {
            result.append(  SyntaxTextData( value: "",
                                            isToken: false ) )
        }
        return result

    }

    func parse( from text: String ) {
        textElements = internalParse( text )
        self.objectWillChange.send()
    }
    
    func removeElement( at index: Int) {
        guard index < textElements.endIndex else { return }

        textElements.remove(at: index)
        
        // compact textElements
        
        var result = Array<SyntaxTextData>()
        
        var current_non_token_string:String?

        textElements.forEach {
            
            if( $0.isToken ) {
                
                if current_non_token_string != nil {
                    result.append( SyntaxTextData( value: current_non_token_string!,
                                                   isToken: false ) )
                    current_non_token_string = nil
                }
                result.append($0)
            }
            else if current_non_token_string != nil {
                current_non_token_string!.append( " \($0.value)" )
            }
            else {
                current_non_token_string = $0.value
            }
        }
        if let current_non_token_string {
            result.append( SyntaxTextData( value: current_non_token_string,
                                           isToken: false ) )
        }
        
        textElements = result
        self.objectWillChange.send()
    }
}


public class UISyntaxTextView: UIView {
    
    private var model  = SyntaxTextModel()
    
    var patterns:Array<SyntaxtTextToken>? {
        get { model.patterns }
        set { model.patterns = newValue }
    }
    
    var padding:UIEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 0)
    
    public var text: String?  = "" {
        didSet {
            internalInit( from: text, startingAt: 0 )
            sizeToFit()
        }
    }

    weak var candidateEditingTextField:UITextField? {
        let textFields = subviews.compactMap { $0 as? UITextField }
        
        if let firstResponder = textFields.first(where: { $0.isFirstResponder } ) {
            return firstResponder
        }
        
        return textFields.first
    }
    
    var delegate:UITextFieldDelegate?

    private weak var internalInputView:UIView?
    
    override public var inputView: UIView? {
        get { internalInputView }
        set {
            internalInputView = newValue
            subviews.compactMap( { $0 as? UITextField } ).forEach { $0.inputView = newValue }
        }
    }

    private weak var internalinputAccessoryView:UIView?

    override public var inputAccessoryView: UIView? {
        get { internalinputAccessoryView }
        set {
            internalinputAccessoryView = newValue
            subviews.compactMap( { $0 as? UITextField } ).forEach { $0.inputAccessoryView = newValue }
        }
    }

    private func initTokenView<TokenView : UIView>( _ subview: TokenView,  token: String, withIndex index: Int ) where TokenView : SyntaxTextView
    {
        subview.tag = index
        subview.layer.borderColor = UIColor.blue.cgColor
        subview.layer.borderWidth = 2
        subview.layer.cornerRadius = 12
        subview.text = token
        subview.onDelete = { [weak self] in
            self?.model.removeElement(at: index)
            self?.reload(startingAt: 0 )
        }
        subview.sizeToFit()
    }

    private func initTextField( text: String?, withIndex index: Int ) -> UITextField {
        
        let subview = UITextField()
        subview.tag = index
        subview.delegate = self
        subview.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular)
//        subview.layer.borderColor = UIColor.black.cgColor
//        subview.layer.borderWidth = 2
        subview.text = text
        subview.inputView = self.inputView
        subview.inputAccessoryView = self.inputAccessoryView
        
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
    
    override public func sizeToFit() {
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
        guard model.isValid( index: start_index ) else {
            return
        }

        print( Self.self, #function )
        
        let syntaxTextSubviews = subviews[start_index..<subviews.endIndex]
        
        syntaxTextSubviews.forEach {
            $0.removeFromSuperview()
        }

        model.indices( from: start_index ).forEach { index in
            
            if let (token,tokenViewFactory) = model.getToken( at: index ) {
                let subview = tokenViewFactory() as! SyntaxTextView
                
                initTokenView( subview, token: token, withIndex: index )
                                
                self.addSubview(subview)
                
            }
            else {
                
                let subview = initTextField( text: model.getText( at: index), withIndex: index )
                
                subview.translatesAutoresizingMaskIntoConstraints = false
                
                self.addSubview(subview)
                
                subview.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
            }
        }
        
        

    }
    
    private func internalInit( from text: String?, startingAt start_index: Int  ) {
        guard let text else { return }
        
        print( Self.self, #function )

        model.parse( from: text )
        
        reload(startingAt: start_index )
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        print( Self.self, #function, self.frame.size)
        
        internalLayoutSubviews()

    }

    @objc func requestBecomeFirstResponder(_ sender: UITapGestureRecognizer? = nil) {
        if let lastTextField = subviews.compactMap( { $0 as? UITextField } ).last {
            lastTextField.becomeFirstResponder()
        }
    }

}

//
// MARK: UITextFieldDelegate extension
//
extension UISyntaxTextView: UITextFieldDelegate {

    private func findFirstTextField( from index: Int ) -> UITextField? {
    
        for i in index..<subviews.endIndex {
            
            if let result = subviews[i] as? UITextField {
                return result
            }
        }
        
        return nil
    }

    private func findFirstTextFieldBackward( from index: Int ) -> UITextField? {
        
        for i in stride(from: index, to: 0, by: -1)  {
            
            if let result = subviews[i] as? UITextField {
                return result
            }
        }
        
        return nil
    }
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textFieldDidBeginEditing?(textField)
    }

    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        delegate?.textFieldDidEndEditing?(textField)
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool  {// called when 'return' key pressed. return NO to ignore.
        return delegate?.textFieldShouldReturn?(textField) ?? true
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
                
        print( Self.self, #function )
        
        guard let previousText = textField.text, let rangeInText = Range(range, in: previousText) else {
            return true
        }
            
        let updatedText = previousText.replacingCharacters(in: rangeInText, with: string)
            
        let index = textField.tag
                
        model.setText( updatedText, at: index)

        let text = model.text
        
        print( Self.self, #function, updatedText  )
        
        if let _ =  string.rangeOfCharacter(from: CharacterSet.whitespaces) {

            if model.match( updatedText ) {

                internalInit( from: text, startingAt: index)
                
                if let nextTextField = findFirstTextField(from: index+1 ){
                
                    nextTextField.becomeFirstResponder()
                    
                    // [getting and setting the cursor position](https://www.programming-books.io/essential/ios/getting-and-setting-the-cursor-position-7729477acddf4aaa8539261a52c5d5ff#2fbd8912-9cba-4666-b1a2-6422911ebd86)

                    let cursor_position = nextTextField.beginningOfDocument
                    nextTextField.selectedTextRange = nextTextField.textRange( from: cursor_position, to: cursor_position)
                    
                }

            }
            
        }

        let _ = delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string ) ?? true
        
        return true
    }
}


public class LineEditorSyntaxTextFieldVC: UIViewController, LineEditorTextField {
    
    private let scrollView = UIScrollView()
    private let contentView = UISyntaxTextView()
    
    public var patterns:Array<SyntaxtTextToken>? {
        get { contentView.patterns }
        set { contentView.patterns = newValue }
    }
    
    var owningCell: UITableViewCell? {
        guard let contentView = view.superview, let cell = contentView.superview as? UITableViewCell else {
            return nil
        }
        return cell

    }
    
    var isPastingContent: Bool = false
    
    var delegate: LineEditorTextFieldDelegate?
    
    var control: UIControl & UITextInput {
        guard let result = contentView.candidateEditingTextField else {
            fatalError("there is no candidateEditingTextField available")
        }
        
        return result
    }
    
    override public var inputView: UIView? {
        get { contentView.inputView }
        set { contentView.inputView = newValue }
    }

    override public var inputAccessoryView: UIView? {
        get { super.inputAccessoryView }
        set { contentView.inputAccessoryView = newValue }
    }

    public var text: String? {
        get { contentView.text }
        set { contentView.text = newValue }
    }
    
    public func updateFont(_ newFont: UIFont) {
        
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupContentView()

//        view.layer.borderColor = UIColor.red.cgColor
//        view.layer.borderWidth = 2

    }
    
    
    private func setupContentView() {
        contentView.delegate = self
        let tap = UITapGestureRecognizer(target: contentView, action: #selector(contentView.requestBecomeFirstResponder(_:)))
        contentView.addGestureRecognizer(tap)
        contentView.isUserInteractionEnabled = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(contentView)
        
        contentView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor).isActive = true
        contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        contentView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
    }
    
    private func setupScrollView() {
        
        scrollView.delegate = self
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        
        scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        scrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    
    override public func viewDidLayoutSubviews() {
        contentView.sizeToFit()
        super.viewDidLayoutSubviews()
        print( Self.self, #function, contentView.frame.size)
        // Do any additional setup after loading the view
        let size = CGSize( width: contentView.frame.size.width + 50, height: contentView.frame.size.height )
        scrollView.contentSize = size
        
//        view.frame.size.height = size.height
    }

}

extension LineEditorSyntaxTextFieldVC: UIScrollViewDelegate {
    
    // [Restrict scrolling direction](https://riptutorial.com/ios/example/31978/restrict-scrolling-direction)
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // only horizontal scroll allowed
        if scrollView.contentOffset.y != 0 {
            scrollView.contentOffset.y = 0
        }
        
    }
}

// MARK: - UITextFieldDelegate
extension LineEditorSyntaxTextFieldVC : UITextFieldDelegate {
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        isPastingContent = false
        
        if let delegate {
            delegate.textFieldDidBeginEditing(self)
        }
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let delegate else { return false }
        
        return delegate.textField(self, shouldChangeCharactersIn: range, replacementString: string)

    }
        
    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        guard let delegate else { return }
        
        delegate.textFieldDidEndEditing(self, reason: reason)

    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool  {// called when 'return' key pressed. return NO to ignore.
        guard let delegate else { return false }
        
        return delegate.textFieldShouldReturn(self)
        
    }

}
