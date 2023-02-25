//
//  File.swift
//  
//
//  Created by Bartolomeo Sorrentino on 25/02/23.
//

import UIKit

class LineEditorTextField : UITextField {
    
    var owningCell:UITableViewCell? {
        guard let contentView = superview, let cell = contentView.superview as? UITableViewCell else {
            return nil
        }
        return cell
    }
    
    private/*(set)*/ var isPastingContent:Bool = false
    
  
    func getAndResetPastingContent() -> [String]? {
        
        guard isPastingContent else {
            return nil
        }
        
        isPastingContent = false
        
        guard let strings = UIPasteboard.general.string  else {
            return nil
        }
        
        return strings.components(separatedBy: "\n")
    }

    open override func paste(_ sender: Any?) {
        isPastingContent = true
        super.paste(sender)
    }

    override func becomeFirstResponder() -> Bool {
        isPastingContent = false
        return super.becomeFirstResponder()
    }
    
    func updateFont( _ newFont: UIFont ) {
        
        if self.font == nil || (self.font != nil &&  newFont.pointSize != self.font!.pointSize) {
            self.font = newFont
        }
        
    }

    @inline(__always)
    func indexPath( for tableView: UITableView ) -> IndexPath? {
        guard let owningCell else  { return nil }

        return tableView.indexPath(for: owningCell)
    }
}
