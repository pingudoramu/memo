import UIKit

class CustomTextView: UITextView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // 检查是否有选中的文本
        guard selectedRange.length > 0 else { return false }
        
        // 定义允许的操作列表
        let allowedActions = [
            #selector(copy(_:)),                    // 复制
            #selector(UIResponderStandardEditActions.paste(_:)),  // 粘贴
            #selector(UIResponderStandardEditActions.select(_:)), // 选择
            #selector(UIResponderStandardEditActions.selectAll(_:)), // 全选
            Selector(("_lookup:")),     // 查找
            Selector(("_translate:")),  // 翻译
            Selector(("_share:"))       // 分享
        ]
        
        return allowedActions.contains(action)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}
