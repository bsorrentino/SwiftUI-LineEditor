//
//  TagView.swift
//  LineEditorSample
//
//  Created by Bartolomeo Sorrentino on 23/02/23.
//

import Foundation
import UIKit

public class UITagView: UIStackView, SyntaxTextView {

    public var padding = UIEdgeInsets(top: 2, left: 10, bottom: 2, right: 5)
    public var font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .regular)
    public var onDelete:(() -> Void)?
    
    private var label = UILabel()
    private var button = UIButton()
    
    public var text:String? {
        get {
            label.text
        }
        set {
            label.text = newValue
        }
        
    }
    
    public init( ) {
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
    
    override public var intrinsicContentSize:CGSize {

        var size = CGSize()

        print( Self.self, #function, button.intrinsicContentSize, label.intrinsicContentSize)

        size.width += padding.left
        size.width += button.intrinsicContentSize.width
        size.width += self.spacing
        size.width += label.intrinsicContentSize.width
        size.width += padding.right
        
        size.height += padding.top
        size.height += max( button.intrinsicContentSize.height, label.intrinsicContentSize.height )
        size.height += padding.bottom


        return size

    }

    override public func sizeToFit() {
//            button.sizeToFit()

//            var size = CGSize( width: button.frame.size.width + padding.left + padding.right,
//                               height: button.frame.size.height )
//
//            print( Self.self, #function, button.frame.size, label.frame.size)
//
//            if let text = label.text {
//
//                let label_size =  text.size(font: font)
//                size.width += label_size.width * 1.1
//                size.height = max(label_size.height, size.height )
//
//            }
//
//            size.height += padding.top + padding.bottom
//            size.width += self.spacing

        self.frame.size = self.intrinsicContentSize
    }

}
