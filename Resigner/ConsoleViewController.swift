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
    }
    
    func appendText(_ text: String) {
        let attrString = NSAttributedString(string: text, attributes: [NSAttributedStringKey.foregroundColor: NSColor.white,
                                                                       NSAttributedStringKey.font: NSFont.systemFont(ofSize: 20) ])
        consoleTextView.textStorage?.append(attrString)
        consoleTextView.scrollRangeToVisible(NSMakeRange(consoleTextView.string.count, 0))
    }
}
