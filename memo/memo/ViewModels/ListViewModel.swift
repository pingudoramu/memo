import Foundation
import Combine

class ListViewModel: ObservableObject {
    @Published var lists: [VocabularyList] = []
    
    init() {
        // Add default list
        lists.append(VocabularyList(name: "default", isDefault: true))
    }
    
    func addList(name: String) {
        let newList = VocabularyList(name: name, isDefault: false)
        lists.append(newList)
    }
    
    func addWord(word: String, sentence: String, toListId: UUID) {
        if let index = lists.firstIndex(where: { $0.id == toListId }) {
            let newWord = WordEntry(word: word, sentence: sentence)
            lists[index].entries.append(newWord)
        }
    }
}
