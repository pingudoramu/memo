import SwiftUI
import UIKit

extension Color {
    static let themeColor = Color(.sRGB, red: 89/255, green: 185/255, blue: 120/255, opacity: 1) //rgb颜色
}

extension UIFont {
    static func rounded(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let font: UIFont
        
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: descriptor, size: size)
        } else {
            font = systemFont
        }
        
        return font
    }
}

struct ContentView: View {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .font: UIFont.rounded(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .font: UIFont.rounded(ofSize: 34, weight: .bold)
        ]
        // 添加 back button 样式
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .font: UIFont.rounded(ofSize: 17, weight: .regular)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        MainView()
            .tint(.themeColor)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
