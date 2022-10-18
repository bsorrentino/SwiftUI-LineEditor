//
//  LineEditorView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI


protocol SharedActions {
    
    func addBelow()
    
    func addAbove()
    
    func toggleCustomKeyobard()


}


struct LineEditorView: UIViewControllerRepresentable, SharedActions {
    
    @Environment(\.editMode) private var editMode
    
    typealias UIViewControllerType = Lines
    
    
    @State var rows = [
    "line1",
    "line2",
    "line3",
    "line1",
    "line2",
    "line3",
    "line1",
    "line2",
    "line3",
    "line1",
    "line2",
    "line3",
    "line1",
    "line2",
    "line3",
    "line1",
    "line2",
    "line3",
    "line1",
    "line2",
    "line_last"
    ]
    
    func makeCoordinator() -> Coordinator {
        Coordinator( owner: self)
    }
    
    func makeUIViewController(context: Context) -> Lines {
        let controller = Lines()
        
        controller.tableView.delegate = context.coordinator
        controller.tableView.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: Lines, context: Context) {
        
        if let isEditing = editMode?.wrappedValue.isEditing {
            print( "editMode: \(isEditing))")
            uiViewController.isEditing = isEditing
        }
    }
    
    func addBelow() {
        
    }
    
    func addAbove() {
        
    }
    
    func toggleCustomKeyobard() {
    }

}

// MARK: - Data Model
extension LineEditorView {
    
    class Line : UITableViewCell {
        
        let textField = UITextField()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            // contentView.isUserInteractionEnabled = false
            
            textField.keyboardType = .asciiCapable
            textField.autocapitalizationType = .none
            textField.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            textField.returnKeyType = .done
            
            contentView.addSubview(textField)
            
            setupContraints()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setupContraints() {
            textField.translatesAutoresizingMaskIntoConstraints = false
            
            let constraints = [
                textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5),
                //textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
                textField.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -15.0),
                textField.heightAnchor.constraint(equalTo: contentView.heightAnchor)
            ]
            
            NSLayoutConstraint.activate(constraints)
        }
        
        
        
    }
    
    
    class Lines : UITableViewController {
        
        
        override func viewDidLoad() {
            tableView.register(LineEditorView.Line.self, forCellReuseIdentifier: "Cell")
            tableView.separatorStyle = .none
            tableView.backgroundColor = UIColor.gray
            isEditing = false
        }
    }
    
}

// MARK: - Coordinator
extension LineEditorView {
    
    
    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIContextMenuInteractionDelegate, SharedActions  {
        
        let HEIGHT = 30.0
        
        var owner: LineEditorView
        
        var accessoryView:  UIView? = nil
        var rightView:      UIView? = nil

        init(owner: LineEditorView ) {
            self.owner = owner
        }
        
        // MARK: - UITableViewDataSource
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            owner.rows.count
        }
        
        private func setupTextField( _ textField: UITextField, withText text:String ) {
            if textField.delegate == nil {
                textField.delegate = self
            }
            
            if textField.rightView == nil {
                textField.rightView = makeRightView()
                textField.rightViewMode = .whileEditing

            }
            if textField.inputAccessoryView == nil {
                textField.inputAccessoryView = makeInputAccesoryView()
            }

            textField.text = text
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            guard let line = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LineEditorView.Line else {
                return UITableViewCell()
            }
            
            setupTextField( line.textField, withText: owner.rows[ indexPath.row ])
            
            
            return line
        }
        
        func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            switch( editingStyle ) {
            case .delete:
                print( "delete" )
                owner.rows.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            case .insert:
                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
                print( "insert" )
            case .none:
                print( "none" )
            @unknown default:
                print( "unknown editingStyle \(editingStyle)" )
            }
        }
        
        func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            
            owner.rows.swapAt(sourceIndexPath.row, destinationIndexPath.row)
            
        }
        // MARK: - UITableViewDelegate
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            HEIGHT
        }
        // MARK: - UITextFieldDelegate
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
        }
        
        func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        }
        
        // MARK: - UIContextMenuInteractionDelegate
    
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            return UIContextMenuConfiguration(identifier: nil,
                                                  previewProvider: nil,
                                              actionProvider: {
                suggestedActions in
                let addAboveAction =
                UIAction(title: NSLocalizedString("Add Above", comment: ""),
                         image: UIImage(systemName: "arrow.up.square")) { action in
                    
                }
                let addBelowAction =
                UIAction(title: NSLocalizedString("Add Below", comment: ""),
                         image: UIImage(systemName: "plus.square.on.square")) { action in
                    
                }
                let cloneRowAction =
                UIAction(title: NSLocalizedString("Clone", comment: ""),
                         image: UIImage(systemName: "trash"),
                         attributes: .destructive) { action in
                    
                }
                let menu =  UIMenu(title: "", children: [addAboveAction, addBelowAction, cloneRowAction])
                
                return menu
            })
        }
        

        private func makeRightView() -> UIView {
            
            if rightView == nil {
                
                let imageView = UIImageView( image: UIImage(systemName: "contextualmenu.and.cursorarrow") )

                let interaction = UIContextMenuInteraction(delegate: self)
                imageView.addInteraction(interaction)


                image.interactions
                rightView = image
            }
            
            return rightView!
        }
        
        private func makeInputAccesoryView() -> UIView {
            
            if accessoryView == nil {

                let bar = UIToolbar()
                let toggleKeyboard = UIBarButtonItem(title: "PlantUML Keyboard", style: .plain, target: self, action: #selector(toggleCustomKeyobard))
                let addBelow = UIBarButtonItem(title: "Add Below", style: .plain, target: self, action: #selector(addBelow ))
                let addAbove = UIBarButtonItem(title: "Add Above", style: .plain, target: self, action: #selector(addAbove))
                bar.items = [
                    toggleKeyboard,
                    addBelow,
                    addAbove
                ]
                bar.sizeToFit()
                accessoryView = bar
            }
            
            return accessoryView!
                
        }
        
        @objc func addBelow() {
            owner.addBelow()
        }
        
        @objc func addAbove() {
            owner.addAbove()
        }
        
        @objc public func toggleCustomKeyobard() {
            owner.toggleCustomKeyobard()
        }
    }
    
}

struct LineEditorView_Previews: PreviewProvider {
    static var previews: some View {
        LineEditorView()
    }
}
