//
//  Application.swift
//  PushTestTool
//
//  Created by Marco on 2020/10/30.
//

import Cocoa

class Application: NSApplication {
    
    let strongDelegate = AppDelegate()

    override init() {
        super.init()
        self.delegate = strongDelegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            if event.modifierFlags.contains(.command)  && NSEvent.ModifierFlags.deviceIndependentFlagsMask.contains(.command) {
                if event.modifierFlags.contains(.shift) && NSEvent.ModifierFlags.deviceIndependentFlagsMask.contains(.shift) {
                    if event.charactersIgnoringModifiers == "Z" {
                        if NSApp.sendAction(Selector("redo:"), to:nil, from:self) { return }
                    }
                }
                guard let key = event.charactersIgnoringModifiers else { return super.sendEvent(event) }
                switch key {
                case "x":
                    if NSApp.sendAction(Selector("cut:"), to:nil, from:self) { return }
                case "c":
                    if NSApp.sendAction(Selector("copy:"), to:nil, from:self) { return }
                case "v":
                    if NSApp.sendAction(Selector("paste:"), to:nil, from:self) { return }
                case "z":
                    if NSApp.sendAction(Selector("undo:"), to:nil, from:self) { return }
                case "a":
                    if NSApp.sendAction(Selector("selectAll:"), to:nil, from:self) { return }
                default:
                    break
              }
            }
        }
        super.sendEvent(event)
    }
    
}
