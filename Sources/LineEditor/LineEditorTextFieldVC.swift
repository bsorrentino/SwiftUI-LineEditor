//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 25/02/23.
//

import UIKit

class LineEditorTextFieldVC : UIViewController, LineEditorTextField {
    
    let textField = UITextField()
    
    var owningCell:UITableViewCell? {
        guard let contentView = textField.superview, let cell = contentView.superview as? UITableViewCell else {
            return nil
        }
        return cell
    }
    
    var isPastingContent:Bool = false
    
    var delegate:LineEditorTextFieldDelegate?

    var control: UIControl & UITextInput  {
        return textField
    }
  
    override var inputView: UIView? {
        get { textField.inputView }
        set { textField.inputView = newValue }
    }

    override var inputAccessoryView: UIView? {
        get { super.inputAccessoryView }
        set { textField.inputAccessoryView = newValue }
    }

    var text:String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    override func loadView() {
        self.view = textField
    }
    
    override func viewDidLoad() {
        textField.delegate = self
        
        textField.accessibilityIdentifier = "LineText"
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done

    }
    
    open override func paste(_ sender: Any?) {
        isPastingContent = true
        super.paste(sender)
    }

    func updateFont( _ newFont: UIFont ) {
        
        if textField.font == nil || (textField.font != nil &&  newFont.pointSize != textField.font!.pointSize) {
            textField.font = newFont
        }
        
    }

}

// MARK: - UITextFieldDelegate
extension LineEditorTextFieldVC : UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isPastingContent = false
        
        if let delegate {
            delegate.textFieldDidBeginEditing(self)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let delegate else { return false }
        
        return delegate.textField(self, shouldChangeCharactersIn: range, replacementString: string)

    }
        
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        guard let delegate else { return }
        
        delegate.textFieldDidEndEditing(self, reason: reason)

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool  {// called when 'return' key pressed. return NO to ignore.
        guard let delegate else { return false }
        
        return delegate.textFieldShouldReturn(self)
        
    }

}
