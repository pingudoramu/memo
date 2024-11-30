import Foundation
import SwiftUI

class WordListViewModel: ObservableObject {
    @Published var wordLists: [VocabularyList] {
        didSet {
            saveWordLists()  // Save whenever wordLists changes
        }
    }
    
    init() {
        // Load saved lists or initialize empty array
        if let data = UserDefaults.standard.data(forKey: "wordLists"),
           let decoded = try? JSONDecoder().decode([VocabularyList].self, from: data) {
            self.wordLists = decoded
        } else {
            // Initialize with empty array instead of default list
            self.wordLists = []
        }
    }
    
    private func saveWordLists() {
        do {
            let encoded = try JSONEncoder().encode(wordLists)
            UserDefaults.standard.set(encoded, forKey: "wordLists")
            print("Data saved successfully") // For debugging
        } catch {
            print("Error saving data: \(error)") // For debugging
        }
    }
    
    // 添加练习结果到历史记录
    func addPracticeResult(_ isCorrect: Bool, for entryId: UUID, in listId: UUID) {
        if let listIndex = wordLists.firstIndex(where: { $0.id == listId }),
           let entryIndex = wordLists[listIndex].entries.firstIndex(where: { $0.id == entryId }) {
            wordLists[listIndex].entries[entryIndex].addPracticeResult(isCorrect)
            saveWordLists()
        }
    }
    
    // Add methods for CRUD operations
    func addWordEntry(_ entry: WordEntry, to listId: UUID) {
        // 首先在所有列表中查找相同的单词+句子组合
        for (listIndex, list) in wordLists.enumerated() {
            if let existingIndex = list.entries.firstIndex(where: { $0.word == entry.word && $0.sentence == entry.sentence }) {
                // 找到了相同的组合，删除它
                wordLists[listIndex].entries.remove(at: existingIndex)
                // 如果这是在同一个列表中，不需要额外操作
                // 如果是在不同的列表中，会在后面添加到新的列表
                saveWordLists()
            }
        }
        
        // 在目标列表中添加新的条目
        if let index = wordLists.firstIndex(where: { $0.id == listId }) {
            // 添加新条目（使用原始的 entry，它的 level 是 1，errorCount 是 0）
            wordLists[index].entries.append(entry)
            lastUsedListId = listId
            saveWordLists()
        }
    }
    
    // Add a method to update error count
    func updateErrorCount(for entryId: UUID, in listId: UUID, increment: Bool = true) {
        if let listIndex = wordLists.firstIndex(where: { $0.id == listId }),
           let entryIndex = wordLists[listIndex].entries.firstIndex(where: { $0.id == entryId }) {
            if increment {
                wordLists[listIndex].entries[entryIndex].errorCount += 1
            } else {
                wordLists[listIndex].entries[entryIndex].errorCount = max(0, wordLists[listIndex].entries[entryIndex].errorCount - 1)
            }
            saveWordLists()
        }
    }
    
    func createList(name: String) {
        let newList = VocabularyList(name: name)
        wordLists.append(newList)
        lastUsedListId = newList.id  // 记录新建的列表
        saveWordLists()
    }
    
    // Add method to delete list
    func deleteList(id: UUID) {
        if lastUsedListId == id {
            // 如果删除的是最后使用的列表，尝试找到前一个可用的列表
            if let newLastUsed = wordLists.first(where: { $0.id != id })?.id {
                lastUsedListId = newLastUsed
            } else {
                lastUsedListId = nil
            }
        }
        wordLists.removeAll(where: { $0.id == id })
        saveWordLists()
    }
    
    // Add method to update list
    func updateList(id: UUID, name: String) {
        if let index = wordLists.firstIndex(where: { $0.id == id }) {
            wordLists[index].name = name
            saveWordLists() // Save after updating list
        }
    }
    
    // Add this function to WordListViewModel
    func deleteEntry(_ entryId: UUID, from listId: UUID) {
        if let listIndex = wordLists.firstIndex(where: { $0.id == listId }) {
            wordLists[listIndex].entries.removeAll(where: { $0.id == entryId })
            saveWordLists() // Save after deleting entry
        }
    }
    
    func setLevel(for entryId: UUID, in listId: UUID, to level: Int) {
        if let listIndex = wordLists.firstIndex(where: { $0.id == listId }),
           let entryIndex = wordLists[listIndex].entries.firstIndex(where: { $0.id == entryId }) {
            wordLists[listIndex].entries[entryIndex].level = max(1, min(6, level))
            saveWordLists()
        }
    }
    
    func incrementLevel(for entryId: UUID, in listId: UUID) {
        if let listIndex = wordLists.firstIndex(where: { $0.id == listId }),
           let entryIndex = wordLists[listIndex].entries.firstIndex(where: { $0.id == entryId }) {
            var entry = wordLists[listIndex].entries[entryIndex]
            entry.level = min(6, entry.level + 1)
            entry.updateNextReviewDate()  // 更新复习时间
            wordLists[listIndex].entries[entryIndex] = entry
            saveWordLists()
        }
    }
    
    func decrementLevel(for entryId: UUID, in listId: UUID) {
        if let listIndex = wordLists.firstIndex(where: { $0.id == listId }),
           let entryIndex = wordLists[listIndex].entries.firstIndex(where: { $0.id == entryId }) {
            var entry = wordLists[listIndex].entries[entryIndex]
            entry.level = max(1, entry.level - 1)
            entry.updateNextReviewDate()  // 更新复习时间
            wordLists[listIndex].entries[entryIndex] = entry
            saveWordLists()
        }
    }
    
    // 检查并更新过期单词 - 现在只更新复习时间，不再自动降级
    func checkExpiredEntries() {
        let now = Date()
        for listIndex in wordLists.indices {
            for entryIndex in wordLists[listIndex].entries.indices {
                let entry = wordLists[listIndex].entries[entryIndex]
                if now > entry.nextReviewDate {
                    // 只更新复习时间，不降级
                    var updatedEntry = entry
                    updatedEntry.updateNextReviewDate()
                    wordLists[listIndex].entries[entryIndex] = updatedEntry
                }
            }
        }
        saveWordLists()
    }
    
//     获取今天需要复习的单词数量
//    func getTodayReviewCount() -> Int {
//        let now = Date()
//        return wordLists.reduce(0) { listCount, list in
//            listCount + list.entries.filter { entry in
//                entry.nextReviewDate <= now
//            }.count
//        }
//    }
  
    // 获取今天需要复习的单词数量
    func getTodayReviewCount() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        
        return wordLists.reduce(0) { listCount, list in
            listCount + list.entries.filter { entry in
                // 如果是首次练习，或者到了复习时间，都应该计入
                entry.isFirstPractice ||
                calendar.startOfDay(for: entry.nextReviewDate) <= startOfToday
            }.count
        }
    }
    
    
//    // 获取所有需要复习的单词
//    func getReviewEntries() -> [WordEntry] {
//        let now = Date()
//        return wordLists.flatMap { list in
//            list.entries.filter { entry in
//                entry.nextReviewDate <= now
//            }
//        }
//    }
    
    // 获取所有需要复习的单词
    func getReviewEntries() -> [WordEntry] {
        let now = Date()
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfToday)!
        
        return wordLists.flatMap { list in
            list.entries.filter { entry in
                // 首次练习的单词
                entry.isFirstPractice ||
                // 今天应该复习的单词（nextReviewDate 正好是今天）
                calendar.isDate(entry.nextReviewDate, inSameDayAs: startOfToday) ||
                // 过期未复习的单词（nextReviewDate 在今天之前）
                entry.nextReviewDate < startOfToday
            }
        }
    }
  
    
    func updateReviewDate(for entryId: UUID, in listId: UUID) {
        if let listIndex = wordLists.firstIndex(where: { $0.id == listId }),
           let entryIndex = wordLists[listIndex].entries.firstIndex(where: { $0.id == entryId }) {
            var entry = wordLists[listIndex].entries[entryIndex]
            entry.updateNextReviewDate()
            wordLists[listIndex].entries[entryIndex] = entry
            saveWordLists()
        }
    }

    
    // 获取特定单词所在的列表 ID
    func getListId(for entryId: UUID) -> UUID? {
        for list in wordLists {
            if list.entries.contains(where: { $0.id == entryId }) {
                return list.id
            }
        }
        return nil
    }
    
    // 添加这个属性来存储/获取最后使用的列表ID
    private var lastUsedListId: UUID? {
        get {
            guard let uuidString = UserDefaults.standard.string(forKey: "lastUsedListId"),
                  let uuid = UUID(uuidString: uuidString) else { return nil }
            // 确保这个列表仍然存在
            return wordLists.contains(where: { $0.id == uuid }) ? uuid : nil
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue.uuidString, forKey: "lastUsedListId")
            } else {
                UserDefaults.standard.removeObject(forKey: "lastUsedListId")
            }
        }
    }
    
    // 添加一个公开的方法来获取最后使用的列表ID
    func getLastUsedListId() -> UUID? {
        return lastUsedListId
    }
    
    // 把 exportLists 方法移到类的内部
    func exportLists() -> [(fileName: String, csvData: String)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        
        return wordLists.map { list in
            // 处理文件名中的非法字符
            let safeFileName = list.name.components(separatedBy: .init(charactersIn: "/\\?%*|\"<>")).joined()
            let fileName = "\(safeFileName).csv"
            
            // CSV 表头
            var csvContent = "Word;Sentence;Level;Created Date;Last Review Date;Next Review Date\n"
            
            // 添加每个单词的数据
            for entry in list.entries {
                let createdDate = dateFormatter.string(from: entry.createdAt)
                let lastReviewDate = dateFormatter.string(from: entry.lastReviewDate)
                let nextReviewDate = dateFormatter.string(from: entry.nextReviewDate)
                
                // 处理句子中的引号和分号
                let escapedSentence = "\"\(entry.sentence.replacingOccurrences(of: "\"", with: "\"\""))\""
                let line = "\(entry.word);\(escapedSentence);\(entry.level);\(createdDate);\(lastReviewDate);\(nextReviewDate)\n"
                csvContent.append(line)
            }
            
            return (fileName, csvContent)
        }
    }
    func setFirstPracticeDone(for entryId: UUID, in listId: UUID) {
        if let listIndex = wordLists.firstIndex(where: { $0.id == listId }),
           let entryIndex = wordLists[listIndex].entries.firstIndex(where: { $0.id == entryId }) {
            wordLists[listIndex].entries[entryIndex].isFirstPractice = false
            wordLists[listIndex].entries[entryIndex].updateNextReviewDate()  // 设置下次复习时间
            saveWordLists()
        }
    }
}
