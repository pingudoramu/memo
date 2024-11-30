import SwiftUI
import UIKit

struct SelectableText: UIViewRepresentable {
    let attributedText: AttributedString
    let didTap: (() -> Void)?
    
    init(attributedText: AttributedString, didTap: (() -> Void)? = nil) {
        self.attributedText = attributedText
        self.didTap = didTap
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = CustomTextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        
        // 设置段落样式以匹配原始布局
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left
        textView.typingAttributes = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 17, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        
        if didTap != nil {
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
            tapGesture.delegate = context.coordinator
            textView.addGestureRecognizer(tapGesture)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        let nsAttributedString = NSAttributedString(attributedText)
        let mutableAttributedString = NSMutableAttributedString(attributedString: nsAttributedString)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left
        
        let range = NSRange(location: 0, length: mutableAttributedString.length)
        mutableAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        
        uiView.attributedText = mutableAttributedString
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(didTap: didTap)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let didTap: (() -> Void)?
        
        init(didTap: (() -> Void)?) {
            self.didTap = didTap
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            didTap?()
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
