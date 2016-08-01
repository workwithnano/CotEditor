/*
 
 ToolbarController.swift
 
 CotEditor
 https://coteditor.com
 
 Created by nakamuxu on 2005-01-07.
 
 ------------------------------------------------------------------------------
 
 © 2004-2007 nakamuxu
 © 2014-2016 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Cocoa

extension LineEnding {
    
    init?(index: Int) {
        
        switch index {
        case 0:
            self = .LF
        case 1:
            self = .CR
        case 2:
            self = .CRLF
        default:
            return nil
        }
    }
    
    
    var index: Int {
        switch self {
        case .LF:
            return 0
        case .CR:
            return 1
        case .CRLF:
            return 2
        default:
            return -1
        }
    }
    
}



final class ToolbarController: NSObject {
    
    // MARK: Public Properties
    
    var document: Document? {
        willSet {
            guard let document = document else { return }
            
            NotificationCenter.default.removeObserver(self, name: .DocumentDidChangeEncoding, object: document)
            NotificationCenter.default.removeObserver(self, name: .DocumentDidChangeLineEnding, object: document)
            NotificationCenter.default.removeObserver(self, name: .DocumentDidChangeSyntaxStyle, object: document)
        }
        
        didSet {
            guard let document = document else { return }
            
            self.invalidateLineEndingSelection()
            self.invalidateEncodingSelection()
            self.invalidateSyntaxStyleSelection()
            self.toolbar?.validateVisibleItems()
            
            // observe document status change
            NotificationCenter.default.addObserver(self, selector: #selector(invalidateEncodingSelection),
                                                   name: .DocumentDidChangeEncoding, object: document)
            NotificationCenter.default.addObserver(self, selector: #selector(invalidateLineEndingSelection),
                                                   name: .DocumentDidChangeLineEnding, object: document)
            NotificationCenter.default.addObserver(self, selector: #selector(invalidateSyntaxStyleSelection),
                                                   name: .DocumentDidChangeSyntaxStyle, object: document)
        }
    }
    
    
    // MARK: Private Properties
    
    @IBOutlet private weak var toolbar: NSToolbar?
    @IBOutlet private weak var lineEndingPopupButton: NSPopUpButton?
    @IBOutlet private weak var encodingPopupButton: NSPopUpButton?
    @IBOutlet private weak var syntaxPopupButton: NSPopUpButton?
    @IBOutlet private weak var shareButton: NSButton?

    
    
    // MARK:
    // MARK: Lifecycle
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    
    // MARK: Object Methods
    
    /// setup UI
    override func awakeFromNib() {
        
        // setup share button
        self.shareButton?.sendAction(on: .leftMouseDown)
        
        self.buildEncodingPopupButton()
        self.buildSyntaxPopupButton()
        
        // observe popup menu line-up change
        NotificationCenter.default.addObserver(self, selector: #selector(buildEncodingPopupButton), name: .EncodingListDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(buildSyntaxPopupButton), name: .SyntaxListDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(buildSyntaxPopupButton), name: .SyntaxHistoryDidUpdate, object: nil)
    }
    
    
    
    // MARK: Private Methods
    
    /// select item in the encoding popup menu
    func invalidateLineEndingSelection() {
        
        guard let lineEnding = self.document?.lineEnding else { return }
        
        self.lineEndingPopupButton?.selectItem(withTag: lineEnding.index)
    }
    
    
    /// select item in the line ending menu
    func invalidateEncodingSelection() {
        
        guard let encoding = self.document?.encoding else { return }
        
        var tag = Int(encoding.rawValue)
        if self.document?.hasUTF8BOM ?? false {
            tag *= -1
        }
        
        self.encodingPopupButton?.selectItem(withTag: tag)
    }
    
    
    /// select item in the syntax style menu
    func invalidateSyntaxStyleSelection() {
        
        guard let popUpButton = self.syntaxPopupButton else { return }
        guard let styleName = self.document?.syntaxStyle.styleName else { return }
        
        popUpButton.selectItem(withTitle: styleName)
        if popUpButton.selectedItem == nil {
            popUpButton.selectItem(at: 0)  // select "None"
        }
    }
    
    
    /// build encoding popup item
    func buildEncodingPopupButton() {
        
        guard let popUpButton = self.encodingPopupButton else { return }
        
        EncodingManager.shared.updateChangeEncodingMenu(popUpButton.menu!)
        
        self.invalidateEncodingSelection()
    }
    
    
    /// build syntax style popup menu
    func buildSyntaxPopupButton() {
        
        guard let menu = self.syntaxPopupButton?.menu else { return }
        
        let styleNames = SyntaxManager.shared.styleNames
        let recentStyleNames = SyntaxManager.shared.recentStyleNames
        let action = #selector(Document.changeSyntaxStyle(_:))
        
        menu.removeAllItems()
        
        menu.addItem(withTitle: BundledStyleName.none, action: action, keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        
        if !recentStyleNames.isEmpty {
            let labelItem = NSMenuItem()
            labelItem.title = NSLocalizedString("Recently Used", comment: "menu heading in syntax style list on toolbar popup")
            labelItem.isEnabled = false
            menu.addItem(labelItem)
            
            for styleName in recentStyleNames {
                menu.addItem(withTitle: styleName, action: action, keyEquivalent: "")
            }
            menu.addItem(NSMenuItem.separator())
        }
        
        for styleName in styleNames {
            menu.addItem(withTitle: styleName, action: action, keyEquivalent: "")
        }
        
        self.invalidateSyntaxStyleSelection()
    }
    
}
