//
//  TPCoreMethodScanner.swift
//  WEKMethodScanner
//
//  Created by Yao Li on 2018/7/16.
//  Copyright © 2018年 yaoli. All rights reserved.
//

import Cocoa

let LinkMapFileRegularExpression = "(?<= [+|-]\\[).+ .+(?=])"
let ASMFileRegularExpression = "__TEXT:__objc_methname:.+"

let WEKMethodScannerNewInfoNotification = "WEKMethodScannerNewInfoNotification"
let WEKMethodScannerProgressNotification = "WEKMethodScannerProgressNotification"

let WEKMethodScannerProgressTotalCountKey = "WEKMethodScannerProgressTotalCountKey"
let WEKMethodScannerProgressCurrentCountKey = "WEKMethodScannerProgressCurrentCountKey"

class WEKMethodScanner: NSObject {
    
    class func start(_ linkMapFilePath: String, asmFilePath: String, whiteListRex: String) -> [String] {
        let unUsedSelector = self.scanAndSearchUnUsedSelector(linkMapFilePath, asmFilePath: asmFilePath, whiteListRex: whiteListRex)
        NotificationCenter.default.post(name: NSNotification.Name(WEKMethodScannerNewInfoNotification), object: nil, userInfo: [NSLocalizedDescriptionKey: "Find \(unUsedSelector.count) Unused Selector!"])
        return unUsedSelector
    }
    
    class private func scanAndSearchUnUsedSelector(_ linkMapFilePath: String, asmFilePath: String, whiteListRex: String) -> Array<String> {
        var linkMapSelectorList: Set<String> = Set()
        var asmMapSelectorList: Set<String> = Set()
        
        let disambleFileString = self.disasmbleAppFile(with: asmFilePath)
        
        NotificationCenter.default.post(name: NSNotification.Name(WEKMethodScannerNewInfoNotification), object: nil, userInfo: [NSLocalizedDescriptionKey: "Prepare to Analyse Selector ..."])
        asmMapSelectorList = Set(self.asmSelectorList(disambleFileString!))
        linkMapSelectorList = Set(self.linkMapSelectorList(linkMapFilePath))
        
        var unUsedSelectorList = [String]()
        var count: Int = 0
        var unusedCount = 0
        let total = linkMapSelectorList.count
        for linkMapLine in linkMapSelectorList {
            var used = false
            if let linkMapselectorName = linkMapLine.grep("(?<= ).+$")?.first {
                if (asmMapSelectorList.contains(linkMapselectorName)) {
                    used = true
                }
            }
            
            count += 1
            NotificationCenter.default.post(name: NSNotification.Name(WEKMethodScannerProgressNotification), object: nil, userInfo: [WEKMethodScannerProgressTotalCountKey: Double(total), WEKMethodScannerProgressCurrentCountKey: Double(count)])
            
            if (!used) {
                let regex = try! NSRegularExpression(pattern: whiteListRex, options: [])
                let matched = regex.firstMatch(in: linkMapLine, options: [], range: NSMakeRange(0, linkMapLine.utf16.count)) != nil

                if (!matched) {
                    unusedCount += 1
                    unUsedSelectorList.append(linkMapLine)
                    NotificationCenter.default.post(name: NSNotification.Name(WEKMethodScannerNewInfoNotification), object: nil, userInfo: [NSLocalizedDescriptionKey: "selector=[\(linkMapLine)], unused/used=\(unusedCount)/\(count), progress: \(count)/\(total)"])
                    print("selector=[\(linkMapLine)], unused/used=\(unusedCount)/\(count), progress: \(count)/\(total)")
                }
            }
        }
        
        unUsedSelectorList = self.sorter(unUsedSelectorList)
        
        return unUsedSelectorList
    }
    
    /// Method Array in Link Map File
    ///
    /// - Returns: [String] format: '+[ClassName function1]'
    class func linkMapSelectorList(_ path: String) -> [String] {
        var resultArray: Array<String> = [String]()
        let linkMapURL = URL(fileURLWithPath: path)
        if let fileHandle = try? FileHandle(forReadingFrom: linkMapURL) {
            let data: Data = fileHandle.readDataToEndOfFile()
            let linkMapString: String? = String(data: data, encoding: String.Encoding.ascii)
            if let array = linkMapString?.grep(LinkMapFileRegularExpression) {
                resultArray = array;
            }
        }
        return resultArray;
    }
    
    
    /// Method Array in ASM file
    ///
    /// - Returns: - Returns: [String] format: 'function1'
    class func asmSelectorList(_ asmString: String) -> [String] {
        var resultArray: Array<String> = [String]()
        if let array = asmString.grep(ASMFileRegularExpression) {
            resultArray = array
        }
        resultArray = resultArray.map({ (asmLine) -> String in
            asmLine.replacingOccurrences(of: "__TEXT:__objc_methname:", with: "")
        })
        return resultArray;
    }
    
    class func disasmbleAppFile(with path: String!) -> String! {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: WEKMethodScannerNewInfoNotification), object: nil, userInfo: [NSLocalizedDescriptionKey: "Disassemble APP File ..."])
        let pathComponents = path.components(separatedBy: "/")
        if let fileName = pathComponents.last?.replacingOccurrences(of: ".app", with: "") {
            let result = self.runCommand(in: path,
                                         launchPath: "/usr/bin/env",
                                         arguments:
                                         "otool",
                                         fileName,
                                         "-v",
                                         "-s",
                                         "__DATA",
                                         "__objc_selrefs"
            )
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: WEKMethodScannerNewInfoNotification), object: nil, userInfo: [NSLocalizedDescriptionKey: "Disassemble APP File Finished!"])
            return result
        }
        return ""
    }
    
    class private func runCommand(in directoryPath: String, launchPath: String, arguments: String...) -> String {
        let pipe = Pipe()
        let fileHanlde = pipe.fileHandleForReading
        fileHanlde.waitForDataInBackgroundAndNotify()
        
        let task = Process()
        task.currentDirectoryPath = directoryPath
        task.launchPath = launchPath
        task.arguments = arguments
        task.standardOutput = pipe
        
        DispatchQueue.main.sync {
            var dataAvailable : NSObjectProtocol!
            dataAvailable = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: fileHanlde, queue: nil) { (notification) in
                let data = pipe.fileHandleForReading.availableData
                if data.count > 0 {
                    if let str = String(data: data, encoding: String.Encoding.utf8) {
                        print("Task sent some data: \(str)")
                    }
                    fileHanlde.waitForDataInBackgroundAndNotify()
                } else {
                    NotificationCenter.default.removeObserver(dataAvailable)
                }
            }
            
            var dataReady : NSObjectProtocol!
            dataReady = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: fileHanlde, queue: nil, using: { (notification) in
                print("Task terminated!")
                NotificationCenter.default.removeObserver(dataReady)
            })
        }
        
        task.launch()
//        task.waitUntilExit()
        
        let data = fileHanlde.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)!
    }
    
    class private func sorter(_ originArray: Array<String>) -> Array<String> {
        let resultArray = originArray.sorted { (str1, str2) -> Bool in
            return str1 < str2
        }
        return resultArray
    }
}
