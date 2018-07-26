//
//  WEKMethodScannerExtension.swift
//  WEKMethodScanner
//
//  Created by Yao Li on 2018/7/25.
//  Copyright © 2018年 yaoli. All rights reserved.
//

import Cocoa

extension String {
    func grep(_ withRegex: String) -> [String]? {
        let regexString = withRegex
        let regex = try! NSRegularExpression(pattern: regexString, options: .caseInsensitive)
        
        let resultArray = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)).map({ (result) -> String in
            let match: NSTextCheckingResult = result as NSTextCheckingResult
            let letterRange = Range(match.range(at: 0), in: self)!
            return String(self[letterRange])
        })
        return resultArray
    }
}

extension NSSavePanel {
    class func tpm_quickSave(in window: NSWindow!, nameField: String!, message: String!, handler: @escaping (NSApplication.ModalResponse, NSSavePanel) -> Swift.Void) {
        let panel = NSSavePanel()
        panel.nameFieldLabel = nameField
        panel.message = message
        panel.allowsOtherFileTypes = false
        panel.isExtensionHidden = true
        panel.canCreateDirectories = true
        panel.beginSheetModal(for: window) { (res) in
            handler(res, panel)
        }
    }
}

extension NSOpenPanel {
    class func tpm_quickOpen(in window: NSWindow!, nameField: String!, message: String!, handler: @escaping (NSApplication.ModalResponse, NSOpenPanel) -> Swift.Void) {
        let panel = NSOpenPanel()
        panel.nameFieldLabel = nameField
        panel.message = message
        panel.allowsOtherFileTypes = true
        panel.isExtensionHidden = true
        panel.canCreateDirectories = true
//        panel.allowedFileTypes = ["xcworkspace"]
        panel.beginSheetModal(for: window) { (res) in
            handler(res, panel)
        }
    }
}
