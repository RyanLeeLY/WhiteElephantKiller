//
//  WEKWindowViewController.swift
//  WhiteElephantKiller
//
//  Created by Yao Li on 2018/7/26.
//  Copyright © 2018年 yaoli. All rights reserved.
//

import Cocoa

class WEKWindowViewController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApp.hide(nil)
        return false
    }
}
