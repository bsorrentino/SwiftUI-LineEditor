//
//  LineEditorView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI
import Combine


public protocol LineEditorKeyboardSymbol {
    
    var value: String {get}
    
    var additionalValues: [String]? {get}
}

public protocol LineEditorKeyboard : View  {
 
    init( onHide: @escaping () -> Void, onPressSymbol: @escaping (LineEditorKeyboardSymbol) -> Void )
    
}

public struct LineEditorView<Element: RawRepresentable<String>, KeyboardView: LineEditorKeyboard>: UIViewControllerRepresentable {
    
    @Environment(\.editMode) private var editMode
    
    public typealias UIViewControllerType = Lines
    
    @Binding var items:Array<Element>
    @Binding var fontSize:CGFloat
    @Binding var showLine:Bool

    public init( items: Binding<Array<Element>>, fontSize:Binding<CGFloat>, showLine:Binding<Bool> ) {
        self._items     = items
        self._fontSize  = fontSize
        self._showLine  = showLine
    }

    public init( items: Binding<Array<Element>> ) {
        self.init( items:items, fontSize: Binding.constant(CGFloat(15.0)), showLine: Binding.constant(false) )
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator( owner: self)
    }
    
    public func makeUIViewController(context: Context) -> Lines {
        let uiViewController = context.coordinator.linesController
        uiViewController.updateState(fontSize: fontSize, showLine: showLine)
        
        return uiViewController
    }
    
    public func updateUIViewController(_ uiViewController: Lines, context: Context) {
        
        if let isEditing = editMode?.wrappedValue.isEditing {
            // print( "editMode: \(isEditing)")
            uiViewController.isEditing = isEditing
        }
        
        uiViewController.updateState(fontSize: fontSize, showLine: showLine)
        
        // items.forEach { print( $0 ) }
    }

}

// MARK: IndexPath extension
extension IndexPath  {

    func isValid<T>( in slice:Array<T> ) -> Bool {
        guard self.row >= slice.startIndex && self.row < slice.endIndex else  {
            return false
        }
        return true
    }

    func testValid<T>( in slice:Array<T> ) -> Self? {
        guard self.row >= slice.startIndex && self.row < slice.endIndex else  {
            return nil
        }
        return self
    }
}

// MARK: - Data Model
extension LineEditorView {
    
    // MARK: - TextField
    class TextField : UITextField {
        
        var owningCell:Line? {
            guard let contentView = superview, let cell = contentView.superview as? Line else {
                return nil
            }
            return cell
        }
        
        private(set) var isPastingContent:Bool = false
        
        
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
            owningCell?.indexPath(for: tableView)
        }
    }
    
    public class Line : UITableViewCell {

        let lineNumber = UILabel()
        let textField = TextField()
        
        
        private var tableView:UITableView {
            guard let tableView = self.superview as? UITableView else {
                fatalError("superview is not a UITableView")
            }
            return tableView
        }
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            self.accessibilityIdentifier = "LineCell"
            self.selectionStyle = .none
            // contentView.isUserInteractionEnabled = false
            
            
            textField.accessibilityIdentifier = "LineText"
            textField.keyboardType = .asciiCapable
            textField.autocapitalizationType = .none
            // textField.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
            textField.returnKeyType = .done
            lineNumber.backgroundColor = UIColor.lightGray
            contentView.addSubview(lineNumber)
            lineNumber.accessibilityIdentifier = "LineLabel"
            contentView.addSubview(textField)
            
            setupContraints()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private var lineConstraints = Array<NSLayoutConstraint>()

        private func setupContraints() {
            
            lineNumber.translatesAutoresizingMaskIntoConstraints = false
            lineConstraints.append( lineNumber.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5) )
            lineConstraints.append( lineNumber.widthAnchor.constraint(equalToConstant: 35 ) )
            lineConstraints.append( lineNumber.heightAnchor.constraint(equalTo: contentView.heightAnchor) )

            textField.translatesAutoresizingMaskIntoConstraints = false
            lineConstraints.append( textField.leadingAnchor.constraint(equalTo: lineNumber.trailingAnchor, constant: 5) )
            lineConstraints.append( textField.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -15.0) )
            lineConstraints.append( textField.heightAnchor.constraint(equalTo: contentView.heightAnchor) )
            
            NSLayoutConstraint.activate(lineConstraints)
        }
        
        func update( at indexPath: IndexPath,
                     coordinator: LineEditorView.Coordinator ) {
               
            lineNumber.text             = "\(indexPath.row)"
            lineNumber.isHidden         = !coordinator.linesController.showLine
            lineConstraints[3].isActive = coordinator.linesController.showLine

            if textField.delegate == nil {
                textField.delegate = coordinator
            }
            
            if textField.rightView == nil {
                textField.rightView = coordinator.rightView
                textField.rightViewMode = .whileEditing
            }
            
            if textField.inputAccessoryView == nil {
                textField.inputAccessoryView = coordinator.inputAccessoryView
            }

            textField.updateFont(coordinator.linesController.font)
            textField.text = coordinator.items[ indexPath.row ].rawValue
        }

        @inline(__always)
        func indexPath( for tableView: UITableView ) -> IndexPath? {
            tableView.indexPath(for: self)
        }
    }
    
    
    public class Lines : UITableViewController {
        
        private var timerCancellable: Cancellable?
        
        var fontSize:CGFloat = 15 {
            didSet {
                if oldValue != fontSize {
                    
                    font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
                }
            }
        }
        
        var showLine:Bool = true

        private(set) var font:UIFont = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        

        func updateState( fontSize:CGFloat, showLine:Bool ) {
            
            var update = false
            
            if self.fontSize != fontSize {
                update = true
                self.fontSize = fontSize
                
            }
            
            if self.showLine != showLine {
                update = true
                self.showLine = showLine
            }
            
            if update {
                tableView.reloadData()
            }
        }
        
        
        public override func viewDidLoad() {
            
            tableView.register(LineEditorView.Line.self, forCellReuseIdentifier: "Cell")
            tableView.separatorStyle = .none
//            tableView.backgroundColor = UIColor.gray
            isEditing = false
        }
                
        func findFirstTextFieldResponder() -> LineEditorView.TextField? {
            
            return tableView.visibleCells
                .compactMap { cell in
                    guard let cell = cell as? LineEditorView.Line else { return nil }
                    return cell.textField
                }
                .first { textField in
                    return textField.isFirstResponder
                }
        }
        
        private func becomeFirstResponder( at indexPath: IndexPath ) -> Bool {
            var done = false
            if let cell = tableView.cellForRow(at: indexPath) as? LineEditorView.Line {
                done  = cell.textField.becomeFirstResponder()
            }
            return done
        }
        
        func becomeFirstResponder( at indexPath: IndexPath, withRetries retries: Int ) {
            
            timerCancellable?.cancel()
            
            if !becomeFirstResponder(at: indexPath) {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true);
                
                timerCancellable = Timer.publish(every: 0.5, on: .main, in: .default)
                    .autoconnect()
                    .prefix( max(retries,1) )
                    .sink { [weak self] _ in
                        
                        if let self = self, self.becomeFirstResponder( at: indexPath)  {
                            print( "becomeFirsResponder: done!")
                            self.timerCancellable?.cancel()
                        }

                    }

            }
                
        }
    }
    
}

// MARK: - Coordinator
extension LineEditorView {
    
    
    public class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate  {
        
        private let ROW_HEIGHT = 30.0
        private let CUSTOM_KEYBOARD_MIN_HEIGHT = 402.0

        private let owner: LineEditorView
        
        var items: Array<Element> {
            owner.items
        }
        
        let linesController = Lines()
                
        private var keyboardRect:CGRect = .zero
        private var keyboardCancellable:AnyCancellable?
        private var showCustomKeyboard:Bool = false
        
        lazy var inputAccessoryView: UIView  = {
            makeInputAccesoryView()
        }()
        
        lazy var rightView: UIView = {
            makeContextMenuView()
        }()

        
        init(owner: LineEditorView ) {
            self.owner = owner
            super.init()
            
            linesController.tableView.delegate = self
            linesController.tableView.dataSource = self

            keyboardCancellable = keyboardRectPublisher.sink {  [weak self] rect in
//                print( "keyboardRect: \(rect)")
                self?.keyboardRect = rect
            }

        }
        
        // MARK: - UITableViewDataSource
        
        private func reloadRows( from indexPath: IndexPath  ) {
//            guard indexPath.isValid( in: owner.items ) else {
//                return
//            }
//
//            let reloadIndexes = Array(indexPath.row...owner.items.count).map { row in
//                IndexPath( row: row, section: indexPath.section)
//            }
//            linesController.tableView.reloadRows(at: reloadIndexes, with: .none)
            
            linesController.tableView.reloadData()
        }
        
        private func disabledCell() -> UITableViewCell {
            let cell =  UITableViewCell()
            cell.selectionStyle = .none
            cell.isUserInteractionEnabled = false
            return cell
        }

        public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            owner.items.count
        }
        
        public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            guard indexPath.isValid( in: owner.items ) else {
                fatalError( "index is no longer valid. indexPath:\(indexPath.row) in [\(owner.items.startIndex), \(owner.items.endIndex)]")
            }

            guard let line = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LineEditorView.Line else {
                return disabledCell()
            }
            
            
            line.update( at: indexPath,
                         coordinator: self)
            
//            print( "cellForRowAt: \(indexPath.row) - \(owner.items[ indexPath.row ].rawValue)")
            
            return line
        }
        
        public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return indexPath.isValid(in: owner.items)
        }
        
        public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            switch( editingStyle ) {
            case .delete:
                print( "delete at \(indexPath.row)" )
                owner.items.remove(at: indexPath.row)
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .fade)
                tableView.endUpdates()
                //tableView.reloadData()
                reloadRows(from: indexPath)
            case .insert:
                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
                print( "insert" )
            case .none:
                print( "none" )
            @unknown default:
                print( "unknown editingStyle \(editingStyle)" )
            }
        }
        
        public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
            return indexPath.isValid(in: owner.items)
        }
        
        public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
            
            if isLastItem( at: destinationIndexPath ) {
                owner.items.append( owner.items.remove(at: sourceIndexPath.row) )
            }
            else {
                owner.items.swapAt(sourceIndexPath.row, destinationIndexPath.row)
            }
            
            reloadRows(from: min( sourceIndexPath, destinationIndexPath ) )
        }
        
        // MARK: - UITableViewDelegate
        
        
        public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            ROW_HEIGHT
        }
     
        // MARK: - UITextFieldDelegate
        
        private func shouldChangeCharactersIn(_ textField: UITextField, in range: NSRange, replacementString input: String) -> Bool {
            
            // skip newline
            // https://stackoverflow.com/a/44939369/521197
            guard input.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
                return false
            }

            guard let textField = textField as? LineEditorView.TextField, let indexPath = textField.indexPath(for: linesController.tableView)?.testValid( in: owner.items ) else {
                return false
            }
            
            if let text = textField.text, let range = Range(range, in: text) {
                if let item = Element(rawValue: text.replacingCharacters(in: range, with: input)) {
                    owner.items[ indexPath.row ] = item
                }
            }

            return true

        }
        
        private func getFromClipboard() -> [String]? {
            
            guard let strings = UIPasteboard.general.string  else {
                return nil
            }
                
            return strings.components(separatedBy: "\n")
        }
        
        public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString input: String) -> Bool {
            
            guard let textField = textField as? LineEditorView.TextField else {
                return false
            }
    
            if textField.isPastingContent, let lines = getFromClipboard() {

                let result = self.shouldChangeCharactersIn(textField, in: range, replacementString: lines[0])

                if lines.count > 1,  let indexPath = textField.indexPath(for: self.linesController.tableView)?.testValid( in: owner.items ) {
                    
                    let elements = lines.enumerated().compactMap { (index, value) in
                        ( index == 0 ) ? nil : Element(rawValue: value)
                    }
                    
                    self.addItemsBelow(elements, at: indexPath)
                }
                
                return result

            }
            
            return  self.shouldChangeCharactersIn(textField, in: range, replacementString: input)
        }
        
        public func textFieldDidBeginEditing(_ textField: UITextField) {
            guard let textField = textField as? LineEditorView.TextField, let indexPath = textField.indexPath(for: linesController.tableView )?.testValid( in: owner.items ) else {
                return
            }
            linesController.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
            guard let textField = textField as? LineEditorView.TextField, let indexPath = textField.indexPath(for: linesController.tableView )?.testValid( in: owner.items ) else {
                return
            }
            linesController.tableView.deselectRow(at: indexPath, animated: false)
        }
        
        public func textFieldShouldReturn(_ textField: UITextField) -> Bool  {// called when 'return' key pressed. return NO to ignore.
            return false
        }
    }
    
}


// MARK: - Coordinator::ItemActions
extension LineEditorView.Coordinator  {
    
    func isLastItem( at indexPath: IndexPath ) -> Bool {
        indexPath.row == owner.items.endIndex - 1
    }

    func isItemsEndIndex( at indexPath: IndexPath ) -> Bool {
        indexPath.row == owner.items.endIndex
    }
    
    func updateItem( at index: Int, withText text: String ) {
        if let item = Element(rawValue: text ) {
            owner.items[ index ] = item
        }

    }
        
    func addItemAbove() {

        if let indexPath = linesController.tableView.indexPathForSelectedRow {
            
            if let newItem = Element(rawValue: "") {

                linesController.tableView.performBatchUpdates {
                    owner.items.insert( newItem, at: indexPath.row )
                    self.linesController.tableView.insertRows(at: [indexPath], with: .automatic )
                        
                } completion: { [unowned self] success in
                    
                    self.reloadRows(from: indexPath)
                    self.linesController.becomeFirstResponder(at: indexPath, withRetries: 0)
                    
                }

            }
        }

    }

    func addItemsBelow( _ items: [Element], at indexPath: IndexPath ) {
        
        let indexes = items
            .enumerated()
            .map { (index, item ) in
                let i = IndexPath( row: indexPath.row + index + 1, section: indexPath.section)
                owner.items.insert( item, at: i.row)
                return i
            }

        linesController.tableView.performBatchUpdates {
                
            self.linesController.tableView.insertRows(at: indexes, with: .automatic )
            
        } completion: { [unowned self] success in

            if let last = indexes.last {
                self.reloadRows( from: last )
                self.linesController.becomeFirstResponder(at: last, withRetries: 5)
            }
            
            
        }

    }
    
    private func addItemBelow( _ newItem: Element, at indexPath: IndexPath ) {
        
        let newIndexPath = IndexPath( row: indexPath.row + 1,
                                      section: indexPath.section )


        linesController.tableView.performBatchUpdates {
            
            if  isItemsEndIndex( at: newIndexPath ) {
                owner.items.append( newItem)
            }
            else {
                owner.items.insert( newItem, at: newIndexPath.row )
            }
            self.linesController.tableView.insertRows(at: [newIndexPath], with: .automatic )
            
        } completion: { [unowned self] success in

            self.reloadRows( from: newIndexPath )

            self.linesController.becomeFirstResponder(at: newIndexPath, withRetries: 5)
            
        }

    }
    
    func addItemBelow() {
        
        if let indexPath = linesController.tableView.indexPathForSelectedRow {
            
            if let newItem = Element(rawValue: "" ) {
                
                addItemBelow( newItem, at: indexPath)
            }
        }
    }
    

    func cloneItem() {
        
        if let indexPath = linesController.tableView.indexPathForSelectedRow {
            
            if let newItem = Element(rawValue: owner.items[ indexPath.row ].rawValue  ) {
                
                addItemBelow( newItem, at: indexPath)
            }
        }
    }

}

// MARK: - Coordinator::Keyboard
extension LineEditorView.Coordinator {
    
    private var keyboardRectPublisher: AnyPublisher<CGRect, Never> {
        // 2.
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map {
                guard let rect = $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return CGRect.zero
                }
                
                return rect
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGRect.zero }
            
        // 3.
        return Publishers.MergeMany(willShow, willHide).eraseToAnyPublisher()
                
    }
    
    func processSymbol(_ symbol: LineEditorKeyboardSymbol, on textField: LineEditorView.TextField) {
        
        // [How to programmatically enter text in UITextView at the current cursor position](https://stackoverflow.com/a/35888634/521197)
        if let indexPath = textField.indexPath(for: linesController.tableView )?.testValid( in: owner.items ), let range = textField.selectedTextRange {
            // From your question I assume that you do not want to replace a selection, only insert some text where the cursor is.
            textField.replace(range, withText: symbol.value )
            if let text = textField.text {
                textField.sendActions(for: .valueChanged)
                
                let offset = indexPath.row
                
                updateItem(at: offset, withText: text )

                if let values = symbol.additionalValues {
                    
                    addItemsBelow(values.compactMap { Element( rawValue: $0) }, at: indexPath)
                }
                // toggleCustomKeyobard()
            }
        }
    }


    private func makeCustomKeyboardRect() -> CGRect {
        var customKeyboardRect = keyboardRect
        
        let MAGIC_NUMBER = 102.0
        
        customKeyboardRect.origin.y += MAGIC_NUMBER
        customKeyboardRect.size.height = max( CUSTOM_KEYBOARD_MIN_HEIGHT, customKeyboardRect.size.height)
        customKeyboardRect.size.height -= MAGIC_NUMBER
        
        return customKeyboardRect

    }
    
    // creation Input View
    private func makeCustomKeyboardView( for textField: LineEditorView.TextField ) -> UIView  {
        
        let keyboardView = KeyboardView(
            onHide: toggleCustomKeyobard,
            onPressSymbol: { [weak self] symbol in
                self?.processSymbol(symbol, on: textField)
            })
        
        let controller = UIHostingController( rootView: keyboardView )
                
        controller.view.frame = makeCustomKeyboardRect()
        
        return controller.view
 
    }
    
    func toggleCustomKeyobard() {
        
//        print( "toggleCustomKeyobard: \(self.showCustomKeyboard)" )
        
        guard let textField = linesController.findFirstTextFieldResponder() else {
            return
        }
        
        showCustomKeyboard.toggle()
        
        if( showCustomKeyboard ) {
            textField.inputView = makeCustomKeyboardView( for: textField )
            
            DispatchQueue.main.async {
                textField.reloadInputViews()
                let _ = textField.becomeFirstResponder()
            }
//            Task {
//
//                let duration = UInt64(0.5 * 1_000_000_000)
//                try? await Task.sleep(nanoseconds: duration )
//
//                textField.reloadInputViews()
//                let _ = textField.becomeFirstResponder()
//
//            }
        }
        else {
            textField.inputView = nil
            textField.reloadInputViews()
        }
        

        
    }

}


// MARK: - Coordinator::UITextField
extension LineEditorView.Coordinator  {
    

    private func makeInputAccesoryView() -> UIView {
        
        let bar = UIToolbar()
        
        let toggleKeyboardTitle = NSLocalizedString("Custom Keyboard", comment: "")
        let toggleKeyboardAction = UIAction(title: toggleKeyboardTitle) { [weak self] action in
            self?.toggleCustomKeyobard()
        }
        let toggleKeyboard = UIBarButtonItem(title: toggleKeyboardTitle,
                                             image: nil,
                                             primaryAction: toggleKeyboardAction )
        
        let addBelowTitle = NSLocalizedString("Add Below", comment: "")
        let addBelowAction = UIAction(title: addBelowTitle) { [weak self] action in
            self?.addItemBelow()
        }
        let addBelow = UIBarButtonItem(title: addBelowTitle,
                                       image: nil,
                                       primaryAction: addBelowAction )
        
        let addAboveTitle = NSLocalizedString("Add Above", comment: "")
        let addAboveAction = UIAction(title: addBelowTitle) { [weak self] action in
            self?.addItemAbove()
        }
        let addAbove = UIBarButtonItem(title: addAboveTitle,
                                       image: nil,
                                       primaryAction: addAboveAction)
        bar.items = [
            toggleKeyboard,
            addBelow,
            addAbove
        ]
        bar.sizeToFit()
        
        return bar
            
    }

}

// MARK: - Coordinator::ContextMenu
extension LineEditorView.Coordinator  {
    
    private func makeContextMenuView() -> UIView {
        
        let image = UIImage(systemName: "contextualmenu.and.cursorarrow")
        
        //            let imageView = UIImageView( image: image )
        //
        //            let interaction = UIContextMenuInteraction(delegate: self)
        //            imageView.addInteraction(interaction)
        //            imageView.isUserInteractionEnabled = true
        //
        //            return imageView
        
        
        let button = UIButton()
        button.setImage( image, for: .normal )
        button.showsMenuAsPrimaryAction = true
        button.menu = makeContextMenu()
        
        return button
    }
    
    private func makeContextMenu() -> UIMenu {
        let addAboveAction =
        UIAction(title: NSLocalizedString("Add Above", comment: ""),
                 image: UIImage(systemName: "arrow.up.square")) { [weak self] action in
            self?.addItemAbove()
        }
        let addBelowAction =
        UIAction(title: NSLocalizedString("Add Below", comment: ""),
                 image: UIImage(systemName: "arrow.down.square")) { [weak self]  action in
            self?.addItemBelow()
        }
        let cloneRowAction =
        UIAction(title: NSLocalizedString("Clone", comment: ""),
                 image: UIImage(systemName: "plus.square.on.square"),
                 attributes: .destructive) { [weak self] action in
            self?.cloneItem()
        }
        return  UIMenu(title: "", children: [addAboveAction, addBelowAction, cloneRowAction])

    }

}

struct LineEditorView_Previews: PreviewProvider {
    
    struct Keyboard: LineEditorKeyboard {
        
        var onHide:() -> Void
        var onPressSymbol: (LineEditorKeyboardSymbol) -> Void

        init(onHide: @escaping () -> Void, onPressSymbol: @escaping (LineEditorKeyboardSymbol) -> Void) {
            self.onHide = onHide
            self.onPressSymbol = onPressSymbol
        }
        
        var body : some View {
            EmptyView()
        }
    }
    
    struct Item: RawRepresentable {
        public var rawValue: String
       
        public init( rawValue: String  ) {
            self.rawValue = rawValue
        }
    }
    
    static var previews: some View {
        LineEditorView<Item, Keyboard>( items: Binding.constant( [
            Item(rawValue: "Item1"),
            Item(rawValue: "Item2"),
            Item(rawValue: "Item3"),
            Item(rawValue: "Item4"),
            Item(rawValue: "Item5"),
            Item(rawValue: "Item6")
        ] ))
    }
}
