//
//  ConsoleViewController.swift
//  Resigner
//
//  Created by Kubrick.G on 2018/10/31.
//  Copyright © 2018年 kubrcik. All rights reserved.
//

import Cocoa

class ConsoleViewController: NSViewController {
    
    @IBOutlet var consoleTextView: NSTextView!
    
    override func viewDidLoad() {
        consoleTextView.backgroundColor = NSColor.black
        consoleTextView.textColor = NSColor.white
    }
    
    func appendText(_ text: String) {
        let attrString = NSAttributedString(string: text)
        consoleTextView.textStorage?.append(attrString)
        consoleTextView.scrollRangeToVisible(NSMakeRange(consoleTextView.string.count, 0))
    }
}
