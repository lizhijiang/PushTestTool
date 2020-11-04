//
//  PushTypeViewController.swift
//  PushTestTool
//
//  Created by Marco on 2020/10/30.
//

import Cocoa

class PushTypeViewController: NSViewController {
    
    var pushTypeView: NSTableView?
    var typeChangeCallback: ((Int) -> ())?
    
    init(typeChange: @escaping (Int) -> ()) {
        self.typeChangeCallback = typeChange
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.frame = NSRect(x: 0, y: 0, width: 160, height: 600)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pushTypeView = NSTableView.init()
        self.pushTypeView?.dataSource = self
        self.pushTypeView?.delegate = self
        self.pushTypeView?.headerView = nil
        
        let tableColumn = NSTableColumn.init(identifier: NSUserInterfaceItemIdentifier(rawValue: "PushType"))
        tableColumn.resizingMask = .autoresizingMask
        tableColumn.width = 160
        self.pushTypeView?.addTableColumn(tableColumn)
        
        let scrollView = NSScrollView(frame: self.view.bounds)
        scrollView.documentView = self.pushTypeView
        scrollView.autoresizingMask = [.width, .height]
        self.view.addSubview(scrollView)
        
        self.pushTypeView?.selectRowIndexes(IndexSet.init(integer: 0), byExtendingSelection: false)
        
    }
    
}

extension PushTypeViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 2
    }
    
    //func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
    //    return row == 0 ? "Token-Based(P8)" : "Certificate-Based(P12)"
    //}
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let textField = NSTextField.init(frame: NSRect(x: 10, y: 10, width: 150, height: 20))
        let cell = NSTableCellView()
        cell.addSubview(textField)
        textField.stringValue = row == 0 ? "Token-Based(P8)" : "Certificate-Based(P12)"
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.isBordered = false
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        if let changeBlock = self.typeChangeCallback, let row = self.pushTypeView?.selectedRow {
            changeBlock(row)
        }
        
    }
    
}
