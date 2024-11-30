import XCTest
@testable import memo
import UIKit

class SelectableTextTests: XCTestCase {
    var textView: CustomTextView!
    
    override func setUp() {
        super.setUp()
        textView = CustomTextView(frame: .zero)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
    }
    
    override func tearDown() {
        textView = nil
        super.tearDown()
    }
    
    func testMenuItems() {
        // 设置测试文本并选中
        let testText = "Test sentence"
        textView.text = testText
        textView.selectedRange = NSRange(location: 0, length: testText.count)
        
        // 测试所有应该支持的操作
        let supportedSelectors = [
            #selector(UIResponderStandardEditActions.copy(_:)),
            #selector(UIResponderStandardEditActions.paste(_:)),
            #selector(UIResponderStandardEditActions.select(_:)),
            #selector(UIResponderStandardEditActions.selectAll(_:)),
            Selector(("_lookup:")),
            Selector(("_translate:")),
            Selector(("_share:"))
        ]
        
        for selector in supportedSelectors {
            XCTAssertTrue(
                textView.canPerformAction(selector, withSender: nil),
                "Should support action: \(selector)"
            )
        }
        
        // 测试一些不应该支持的操作
        let unsupportedSelectors = [
            #selector(UIResponderStandardEditActions.cut(_:)),
            #selector(UIResponderStandardEditActions.delete(_:))
        ]
        
        for selector in unsupportedSelectors {
            XCTAssertFalse(
                textView.canPerformAction(selector, withSender: nil),
                "Should not support action: \(selector)"
            )
        }
    }
    
    func testNoSelectionMenuItems() {
        // 测试没有选中文本时的情况
        textView.text = "Test sentence"
        textView.selectedRange = NSRange(location: 0, length: 0)
        
        let selector = #selector(UIResponderStandardEditActions.copy(_:))
        XCTAssertFalse(textView.canPerformAction(selector, withSender: nil))
    }
}
