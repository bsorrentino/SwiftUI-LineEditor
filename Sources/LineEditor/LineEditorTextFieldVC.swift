//
//  LineEditorTextFieldVC.swift
//  
//
//  Created by Bartolomeo Sorrentino on 25/02/23.
//

import UIKit

public class LineEditorTextFieldVC : UIViewController, LineEditorTextField {
    
    let textField = UITextField()
    
    public var owningCell:UITableViewCell? {
        guard let contentView = textField.superview, let cell = contentView.superview as? UITableViewCell else {
            return nil
        }
        return cell
    }
    
    public var isPastingContent:Bool = false
    
    public var delegate:LineEditorTextFieldDelegate?

    public var control: UIControl & UITextInput  {
        return textField
    }
  
    override public var inputView: UIView? {
        get { textField.inputView }
        set { textField.inputView = newValue }
    }

    override public var inputAccessoryView: UIView? {
        get { super.inputAccessoryView }
        set { textField.inputAccessoryView = newValue }
    }

    public var text:String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    public var font:UIFont? {
        get { textField.font }
        set { textField.font = newValue }
    }

    public override func loadView() {
        self.view = textField
    }
    
    public override func viewDidLoad() {
        textField.delegate = self
        textField.pasteDelegate = self
        textField.accessibilityIdentifier = "LineText"
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        
        textField.addTarget(self, action: #selector(self.editingChanged), for: .editingChanged)

    }

//    open override func paste(_ sender: Any?) {
//        isPastingContent = true
//        super.paste(sender)
//    }

}

// MARK: - UITextPasteDelegate
extension LineEditorTextFieldVC : UITextPasteDelegate {
    
    public func textPasteConfigurationSupporting(_ textPasteConfigurationSupporting: UITextPasteConfigurationSupporting, transform item: UITextPasteItem) {
        
        isPastingContent = true
        
        item.setDefaultResult()
    }
}

// MARK: - UITextFieldDelegate
extension LineEditorTextFieldVC : UITextFieldDelegate {
    
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
            
    @objc private func editingChanged(_ textField: UITextField) {
        guard let delegate else { return }
        
        return delegate.editingChanged(self)
    }

}
