//
//  LineEditorView.swift
//  LineEditor
//
//  Created by Bartolomeo Sorrentino on 17/10/22.
//

import SwiftUI


class Line : UITableViewCell {
    
    let textField = UITextField()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.isUserInteractionEnabled = false

        textField.frame = self.bounds;
        textField.keyboardType = .asciiCapable
        textField.returnKeyType = .done
        addSubview(textField)
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Lines : UITableViewController {
    
    
    override func viewDidLoad() {
        tableView.register(Line.self, forCellReuseIdentifier: "Cell")
        tableView.separatorStyle = .none

    }
}



struct LineEditorView: UIViewControllerRepresentable {

    typealias UIViewControllerType = Lines

    func makeCoordinator() -> Coordinator {
        Coordinator( rows:[
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
            "line_last",
        ])
    }
    func makeUIViewController(context: Context) -> Lines {
        let controller = Lines()
        
        controller.tableView.delegate = context.coordinator
        controller.tableView.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: Lines, context: Context) {
        
    
    }
    
    
}


extension LineEditorView {
    
    
    class Coordinator: NSObject, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {
    
        var rows: [String]

        init(rows: [String]) {
            self.rows = rows
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            rows.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            
            guard let line = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? Line else {
                return UITableViewCell()
            }
            
            
            line.textField.delegate = self
            line.textField.text = rows[ indexPath.row ]
            
            return line
        }
        
        
        
    }
    
}

struct LineEditorView_Previews: PreviewProvider {
    static var previews: some View {
        LineEditorView()
    }
}
