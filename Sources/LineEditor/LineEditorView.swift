//
//  LineEditorView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI
import Combine

public protocol LineEditorTextField : UIViewController, UIResponderStandardEditActions {
    
    var owningCell:UITableViewCell? { get }
    
    var isPastingContent:Bool { get set }
    
    var delegate:LineEditorTextFieldDelegate? { get set }

    var control: UIControl & UITextInput  { get }

    var inputView: UIView? { get set }

    var inputAccessoryView: UIView? { get set }

    var text:String? { get set }

    var font: UIFont? { get set }
    
    init()
    
    func getAndResetPastingContent() -> [String]?

    func indexPath( for tableView: UITableView ) -> IndexPath?

}

public extension LineEditorTextField {
    
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

    @inline(__always)
    func indexPath( for tableView: UITableView ) -> IndexPath? {
        guard let owningCell else  { return nil }

        return tableView.indexPath(for: owningCell)
    }

}

@MainActor public protocol LineEditorTextFieldDelegate : NSObjectProtocol {
    
    func textField(_ textField: LineEditorTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    
    func textFieldDidBeginEditing(_ textField: LineEditorTextField)
    
    func textFieldDidEndEditing(_ textField: LineEditorTextField, reason: UITextField.DidEndEditingReason)
    
    func textFieldShouldReturn(_ textField: LineEditorTextField) -> Bool
    
}

public protocol LineEditorKeyboardSymbol : Identifiable<String> {
    
    var value: String {get}
    
    var additionalValues: [String]? {get}
}

public struct LineEditorView<Element: RawRepresentable<String>,
                             Symbol: LineEditorKeyboardSymbol,
                             TextEditor: LineEditorTextField> : UIViewControllerRepresentable {
   
    public typealias KeyboardContent = (_ onHide: @escaping () -> Void,
                                        _ onPressSymbol: @escaping (Symbol) -> Void) -> any View

    @Environment(\.editMode) private var editMode
    
    public typealias UIViewControllerType = Lines
    
    @Binding private var items:Array<Element>
    @Binding private var fontSize:CGFloat
    @Binding private var showLine:Bool

    private var keyboardView: KeyboardContent
    
    public init( items: Binding<Array<Element>>, fontSize:Binding<CGFloat>, showLine:Binding<Bool>, @ViewBuilder keyboardView: @escaping KeyboardContent ) {
        
        self._items     = items
        self._fontSize  = fontSize
        self._showLine  = showLine
        self.keyboardView = keyboardView
    }

    public init( items: Binding<Array<Element>>, @ViewBuilder keyboardView: @escaping KeyboardContent ) {
        self.init( items:items, fontSize: Binding.constant(CGFloat(15.0)), showLine: Binding.constant(false), keyboardView: keyboardView )
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator( owner: self)
    }
    
    public func makeUIViewController(context: Context) -> Lines {
        let uiViewController = context.coordinator.linesController
        
        return uiViewController
    }
    
    public func updateUIViewController(_ uiViewController: Lines, context: Context)  {
        
        Task {
            await uiViewController.updateState(fontSize: fontSize,
                                               showLine: showLine,
                                               isEditing: editMode?.wrappedValue.isEditing ?? false)
        }
    }

}

// MARK: IndexPath extension
extension IndexPath  {

    func isLast<T>( in slice:Array<T> ) -> Bool {
        self.row == slice.endIndex - 1
    }

    func isEndIndex<T>( in slice:Array<T> ) -> Bool {
        self.row == slice.endIndex
    }
 
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
    
    @inline(__always)
    func add( row: Int) -> IndexPath {
        IndexPath( row: self.row + row, section: self.section )
    }
}


extension LineEditorView {
        
    // MARK: - UITableViewCell
    public class Line : UITableViewCell {

        let lineNumber = UILabel()
        let textFieldController = TextEditor()
        
        
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
                        
            lineNumber.accessibilityIdentifier = "LineLabel"
            lineNumber.backgroundColor = UIColor.lightGray
            contentView.addSubview(lineNumber)
            contentView.addSubview(textFieldController.view)
            
            setupContraints()
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private var textFieldLeadingContraintsRelativeToLineNumber:NSLayoutConstraint?

        private func setupContraints() {
            
            var lineConstraints = Array<NSLayoutConstraint>()

            lineNumber.translatesAutoresizingMaskIntoConstraints = false
            lineConstraints.append( lineNumber.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5) )
            lineConstraints.append( lineNumber.widthAnchor.constraint(equalToConstant: 35 ) )
            lineConstraints.append( lineNumber.heightAnchor.constraint(equalTo: contentView.heightAnchor) )

            textFieldController.view.translatesAutoresizingMaskIntoConstraints = false

            let textFieldLeadingContraints = textFieldController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 5)
            textFieldLeadingContraints.priority = UILayoutPriority(500)
            
            lineConstraints.append( textFieldLeadingContraints )
            lineConstraints.append( textFieldController.view.widthAnchor.constraint(equalTo: contentView.widthAnchor, constant: -15.0) )
            lineConstraints.append( textFieldController.view.heightAnchor.constraint(equalTo: contentView.heightAnchor) )
            
            NSLayoutConstraint.activate(lineConstraints)

            textFieldLeadingContraintsRelativeToLineNumber =
            textFieldController.view.leadingAnchor.constraint(equalTo: lineNumber.trailingAnchor, constant: 5)
            textFieldLeadingContraintsRelativeToLineNumber?.priority = UILayoutPriority(1000)
            

        }
        
        
        func update( at indexPath: IndexPath,
                     coordinator: LineEditorView.Coordinator ) {
            
            
            lineNumber.text             = "\(indexPath.row)"
            lineNumber.isHidden         = !coordinator.linesController.showLine
            textFieldLeadingContraintsRelativeToLineNumber?.isActive = !lineNumber.isHidden
            
            if textFieldController.delegate == nil {
                textFieldController.delegate = coordinator
            }
            
            #if _CONTEXT_MENU
            if textFieldController.rightView == nil {
                textFieldController.rightView = coordinator.rightView
                textFieldController.rightViewMode = .whileEditing
            }
            #endif
            
            if textFieldController.inputAccessoryView == nil {
                textFieldController.inputAccessoryView = coordinator.inputAccessoryView
            }

            textFieldController.font = coordinator.linesController.font
            textFieldController.text = coordinator.items[ indexPath.row ].rawValue

        }

        @inline(__always)
        func indexPath( for tableView: UITableView ) -> IndexPath? {
            tableView.indexPath(for: self)
        }
    }
    
    // MARK: - UITableViewController
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
        

        func updateState( fontSize:CGFloat, showLine:Bool, isEditing: Bool ) async  {
            
            var requestReload = false
            
            if self.fontSize != fontSize {
                requestReload = true
                self.fontSize = fontSize
                
            }
            
            if self.showLine != showLine {
                requestReload = true
                self.showLine = showLine
            }
            
            if( self.isEditing != isEditing ) {
                
                if isEditing {
                    let _ = resignTextFieldFirstResponder()
                }
                
                self.isEditing = isEditing
            }
             
            if requestReload {
                await MainActor.run {
                    tableView.reloadData()
                }
            }
        }
        
        
        public override func viewDidLoad() {
            
            tableView.register(LineEditorView.Line.self, forCellReuseIdentifier: "Cell")
            tableView.separatorStyle = .none
//            tableView.backgroundColor = UIColor.gray
            isEditing = false
        }
                
        func findTextFieldFirstResponder() -> TextEditor? {
            
            return tableView.visibleCells
                .compactMap { cell in
                    guard let cell = cell as? LineEditorView.Line else { return nil }
                    return cell.textFieldController
                }
                .first { textField in
                    return textField.control.isFirstResponder
                }
        }
        
        func resignTextFieldFirstResponder() -> Bool {
            guard let textField = findTextFieldFirstResponder() else {
                return false
            }
            
            return textField.control.resignFirstResponder()
        }
        
        private func becomeTextFieldFirstResponder( at indexPath: IndexPath ) -> Bool {
            var done = false
            if let cell = tableView.cellForRow(at: indexPath) as? LineEditorView.Line {
                done  = cell.textFieldController.control.becomeFirstResponder()
            }
            return done
        }
        
        func becomeTextFieldFirstResponder( at indexPath: IndexPath, withRetries retries: Int ) {
            
            timerCancellable?.cancel()
            
            if !self.becomeTextFieldFirstResponder(at: indexPath) {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true);
                
                timerCancellable = Timer.publish(every: 0.5, on: .main, in: .default)
                    .autoconnect()
                    .prefix( max(retries,1) )
                    .sink { [unowned self] _ in
                        
                        if self.becomeTextFieldFirstResponder( at: indexPath)  {
//                            print( "becomeFirsResponder: done!")
                            self.timerCancellable?.cancel()
                        }

                    }

            }
                
        }
    }
    
}

// MARK: - Coordinator
extension LineEditorView {
    
    
    public class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, LineEditorTextFieldDelegate  {
        
        private let ROW_HEIGHT = CGFloat(30.0)
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
        
        #if _CONTEXT_MENU
        lazy var rightView: UIView = {
            makeContextMenuView()
        }()
        #endif

        
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
        
        public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            owner.items.count
        }
        
        public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            guard let line = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? LineEditorView.Line else {
                fatalError( "tableView.dequeueReusableCell returns NIL")
            }
            
            line.update( at: indexPath,
                         coordinator: self)
            
//            linesController.addChild(line.textFieldController)
//            line.textFieldController.didMove(toParent: linesController)


            return line
        }
        
        public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return indexPath.isValid(in: owner.items)
        }
        
        
        public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            switch( editingStyle ) {
            case .delete:
                Task {
                    await deleteItem(in: tableView, atRow: indexPath)
                }
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
            Task {
                await moveItem(in: tableView, fromRow: sourceIndexPath, toRow: destinationIndexPath)
            }
        }
        
        // MARK: - UITableViewDelegate
        
        
        public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            
            ROW_HEIGHT
            
        }
     
        // MARK: - UITextFieldDelegate
        
        internal func shouldChangeCharactersIn(_ textField: LineEditorTextField, in range: NSRange, replacementString input: String) -> Bool {
            
            // skip newline
            // https://stackoverflow.com/a/44939369/521197
            guard input.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
                return false
            }

            guard let indexPath = textField.indexPath(for: linesController.tableView)?.testValid( in: owner.items ) else {
                return false
            }
            
            if let previousText = textField.text, let rangeInText = Range(range, in: previousText) {
                
                let updatedText = previousText.replacingCharacters(in: rangeInText, with: input)
                
                if let item = Element( rawValue: updatedText ) {
                    owner.items[ indexPath.row ] = item
                }
            }

            return true

        }
        
     
        public func textField(_ textField: LineEditorTextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            
            if let lines = textField.getAndResetPastingContent() {

                let result = self.shouldChangeCharactersIn(textField, in: range, replacementString: lines[0])

                if lines.count > 1,  let indexPath = textField.indexPath(for: self.linesController.tableView)?.testValid( in: owner.items ) {
                    
                    let elements = lines.enumerated().compactMap { (index, value) in
                        ( index == 0 ) ? nil : Element(rawValue: value)
                    }
                    
                    Task {
                        await self.addItemsBelow(elements, in: self.linesController.tableView, atRow: indexPath)
                    }
                }
                
                return result

            }
            
            return  self.shouldChangeCharactersIn(textField, in: range, replacementString: string)
        }
        
        public func textFieldDidBeginEditing(_ textField: LineEditorTextField) {
            guard let indexPath = textField.indexPath(for: linesController.tableView )?.testValid( in: owner.items ) else {
                return
            }
            linesController.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        public func textFieldDidEndEditing(_ textField: LineEditorTextField, reason: UITextField.DidEndEditingReason) {
            guard let indexPath = textField.indexPath(for: linesController.tableView )?.testValid( in: owner.items ) else {
                return
            }
            linesController.tableView.deselectRow(at: indexPath, animated: false)
        }
        
        public func textFieldShouldReturn(_ textField: LineEditorTextField) -> Bool  {// called when 'return' key pressed. return NO to ignore.
            guard let indexPath = textField.indexPath(for: linesController.tableView )?.testValid( in: owner.items ) else {
                return false
            }
            
            // Move cursor to next line or adds item below if doesn't exist
//            if let nextIndex = indexPath.add( row: 1 ).testValid(in: owner.items) {
//
//                linesController.becomeTextFieldFirstResponder(at: nextIndex, withRetries: 1)
//                return true
//            }

            // Add item below
            if let newItem = Element(rawValue: "") {
                Task {
                    await addItemBelow( newItem, in: linesController.tableView, atRow: indexPath )
                }
                return true
            }
            
            return false
        }
    }
    
}


// MARK: - Coordinator::Update Model
extension LineEditorView.Coordinator  {
    
    
    private func reloadVisibleRows( startingFrom indexPath: IndexPath  ) async {
        guard indexPath.isValid( in: owner.items ), let visibleRows = linesController.tableView.indexPathsForVisibleRows  else {
            return
        }
        
        let reloadIndexes = visibleRows.filter { ip in
            ip.row >= indexPath.row
        }
        
        await MainActor.run {
            linesController.tableView.reloadRows(at: reloadIndexes, with: .none)
        }
    }

    func moveItem( in tableView: UITableView, fromRow sourceIndexPath: IndexPath, toRow destinationIndexPath: IndexPath ) async {
        
        if destinationIndexPath.isLast( in: owner.items ) {
            owner.items.append( owner.items.remove(at: sourceIndexPath.row) )
        }
        else {
            owner.items.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        }
        
        await reloadVisibleRows(startingFrom: min( sourceIndexPath, destinationIndexPath ) )

    }

    func deleteItem( in tableView: UITableView, atRow indexPath: IndexPath ) async {

        owner.items.remove(at: indexPath.row)
        await MainActor.run {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        await self.reloadVisibleRows(startingFrom: indexPath)
    }
    
    func updateItem( at index: Int, withText text: String ) {
        if let item = Element(rawValue: text ) {
            owner.items[ index ] = item
        }

    }
        
    func addItemAbove( in tableView: UITableView, atRow indexPath: IndexPath) async {

        if let newItem = Element(rawValue: "") {

            owner.items.insert( newItem, at: indexPath.row )
            await MainActor.run {
                tableView.insertRows(at: [indexPath], with: .automatic )
            }
            await self.reloadVisibleRows(startingFrom: indexPath)
            
            self.linesController.becomeTextFieldFirstResponder(at: indexPath, withRetries: 0)
        }
    }

    func addItemsBelow( _ items: [Element], in tableView: UITableView, atRow indexPath: IndexPath ) async  {
        
        let indexes = items
            .enumerated()
            .map { (index, item ) in
                let i = IndexPath( row: indexPath.row + index + 1, section: indexPath.section)
                owner.items.insert( item, at: i.row)
                return i
            }

        await MainActor.run {
            tableView.insertRows(at: indexes, with: .automatic )
        }
        
        await self.reloadVisibleRows( startingFrom: indexes.last! )
        
        self.linesController.becomeTextFieldFirstResponder(at: indexes.last! , withRetries: 5)

    }
    
    private func addItemBelow( _ newItem: Element, in tableView: UITableView, atRow indexPath: IndexPath ) async {
        
        let newIndexPath = indexPath.add( row: 1 )

        if  newIndexPath.isEndIndex( in: owner.items ) {
            owner.items.append( newItem)
        }
        else {
            owner.items.insert( newItem, at: newIndexPath.row )
        }
    
        await MainActor.run {
            tableView.insertRows(at: [newIndexPath], with: .automatic )
        }
        
        await reloadVisibleRows( startingFrom: newIndexPath )

        linesController.becomeTextFieldFirstResponder(at: newIndexPath, withRetries: 5)
    }
    
    func addItemBelow() async {
        
        if let indexPath = linesController.tableView.indexPathForSelectedRow {
            
            if let newItem = Element(rawValue: "" ) {
                
                await addItemBelow( newItem, in: linesController.tableView, atRow: indexPath)
            }
        }
    }
    

    func cloneItem() async {
        
        if let indexPath = linesController.tableView.indexPathForSelectedRow {
            
            if let newItem = Element(rawValue: owner.items[ indexPath.row ].rawValue  ) {
                
                await addItemBelow( newItem, in: linesController.tableView, atRow: indexPath)
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
    
    func processSymbol(_ symbol: Symbol, on textField: TextEditor) {
        
        // [How to programmatically enter text in UITextView at the current cursor position](https://stackoverflow.com/a/35888634/521197)
        if let indexPath = textField.indexPath(for: linesController.tableView )?.testValid( in: owner.items ), let range = textField.control.selectedTextRange {
            // From your question I assume that you do not want to replace a selection, only insert some text where the cursor is.
            textField.control.replace(range, withText: symbol.value )
            if let text = textField.text {
                textField.control.sendActions(for: .valueChanged)
                
                let offset = indexPath.row
                
                updateItem(at: offset, withText: text )

                if let values = symbol.additionalValues {
                    
                    Task {
                        await addItemsBelow(values.compactMap { Element( rawValue: $0) }, in: linesController.tableView, atRow: indexPath)
                    }
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
    private func makeCustomKeyboardView( for textField: TextEditor ) -> UIView  {
        
        let keyboardView = owner.keyboardView(
            /*onHide:*/ toggleCustomKeyobard,
            /*onPressSymbol:*/ { [weak self] symbol in
                self?.processSymbol(symbol, on: textField)
            })
        
        let controller = UIHostingController( rootView: AnyView(keyboardView) )
                
        controller.view.frame = makeCustomKeyboardRect()
        
        return controller.view
 
    }
    
    func toggleCustomKeyobard() {
        
//        print( "toggleCustomKeyobard: \(self.showCustomKeyboard)" )
        
        guard let textField = linesController.findTextFieldFirstResponder() else {
            return
        }
        
        showCustomKeyboard.toggle()
        
        if( showCustomKeyboard ) {
            textField.inputView = makeCustomKeyboardView( for: textField )
            
            DispatchQueue.main.async {
                textField.control.reloadInputViews()
                let _ = textField.control.becomeFirstResponder()
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
            textField.control.reloadInputViews()
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
            Task {
                await self?.addItemBelow()
            }
        }
        let addBelow = UIBarButtonItem(title: addBelowTitle,
                                       image: nil,
                                       primaryAction: addBelowAction )
        
        let addAboveTitle = NSLocalizedString("Add Above", comment: "")
        let addAboveAction = UIAction(title: addBelowTitle) { [weak self] action in
            
            if let tableView = self?.linesController.tableView, let indexPath = tableView.indexPathForSelectedRow {
                
                Task {
                    await self?.addItemAbove( in: tableView, atRow: indexPath )
                }
            }
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
            if let tableView = self?.linesController.tableView, let indexPath = tableView.indexPathForSelectedRow {
                
                Task {
                    await self?.addItemAbove( in: tableView, atRow: indexPath )
                }
            }
        }
        let addBelowAction =
        UIAction(title: NSLocalizedString("Add Below", comment: ""),
                 image: UIImage(systemName: "arrow.down.square")) { [weak self]  action in
            
            Task {
                await self?.addItemBelow()
            }
        }
        let cloneRowAction =
        UIAction(title: NSLocalizedString("Clone", comment: ""),
                 image: UIImage(systemName: "plus.square.on.square"),
                 attributes: .destructive) { [weak self] action in
            Task {
                await self?.cloneItem()
            }
        }
        return  UIMenu(title: "", children: [addAboveAction, addBelowAction, cloneRowAction])

    }

}

public typealias StandardLineEditorView<Element: RawRepresentable<String>,
                                Symbol: LineEditorKeyboardSymbol> = LineEditorView<Element,Symbol,LineEditorTextFieldVC>


struct GenericLineEditorView_Previews: PreviewProvider {
    
    struct KeyboardSymbol : LineEditorKeyboardSymbol {
        var value: String
        
        var additionalValues: [String]?
        
        var id: String
        
    }
    
    struct Keyboard: View {
        
        var onHide:() -> Void
        var onPressSymbol: (KeyboardSymbol) -> Void
  
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
    
    class MyLineEditorTextFieldVC : LineEditorSyntaxTextFieldVC {
        
        static let line_begin_keywords = "(?i)^\\s*(usecase|actor|object|participant|boundary|control|entity|database|create|component|interface|package|node|folder|frame|cloud|annotation|class|state|autonumber|group|box|rectangle|namespace|partition|archimate|sprite)\\b"

        static let tokens = [
            SyntaxtTextToken( pattern: line_begin_keywords,
                              tokenFactory: {  UITagView() } )
        ]
        override func viewDidLoad() {
            
            self.patterns = Self.tokens
            
            super.viewDidLoad()
        }
    }
    
    
    static var previews: some View {
        
        Group {
            
            StandardLineEditorView<Item, KeyboardSymbol>( items: Binding.constant( [
                Item(rawValue: "Item1"),
                Item(rawValue: "Item2"),
                Item(rawValue: "Item3"),
                Item(rawValue: "Item4"),
                Item(rawValue: "Item5"),
                Item(rawValue: "Item6")
            ] ), keyboardView: { onHide, onPressSymbol in
                Keyboard( onHide: onHide, onPressSymbol: onPressSymbol )
            })
            
            LineEditorView<Item, KeyboardSymbol, MyLineEditorTextFieldVC>( items: Binding.constant( [
                Item(rawValue: "Item1"),
                Item(rawValue: "Item2"),
                Item(rawValue: "Item3"),
                Item(rawValue: "Item4"),
                Item(rawValue: "Item5"),
                Item(rawValue: "Item6")
            ] ), keyboardView: { onHide, onPressSymbol in
                Keyboard( onHide: onHide, onPressSymbol: onPressSymbol )
            })

        }
    }
}
