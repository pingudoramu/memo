import Foundation

struct PracticeSession {
    // Current practice state
    private(set) var currentWords: [WordEntry]
    private(set) var incorrectAnswers: Set<UUID> = []
    private(set) var completedWords: Set<UUID> = []
    
    // Settings
    let wordsPerGroup: Int
    var isReadAloudEnabled: Bool
    
    init(words: [WordEntry], wordsPerGroup: Int = 3, isReadAloudEnabled: Bool = false) {
        self.currentWords = words
        self.wordsPerGroup = wordsPerGroup
        self.isReadAloudEnabled = isReadAloudEnabled
    }
    
    // 获取当前组的单词
    var currentGroup: [WordEntry] {
        Array(currentWords.prefix(wordsPerGroup))
    }
    
    // 检查答案
    mutating func checkAnswer(wordId: UUID, answer: String) -> Bool {
        guard let word = currentWords.first(where: { $0.id == wordId }) else { return false }
        let isCorrect = word.word.lowercased() == answer.lowercased()
        
        if !isCorrect {
            incorrectAnswers.insert(wordId)
        }
        completedWords.insert(wordId)
        return isCorrect
    }
    
    // 检查当前组是否完成
    var isGroupCompleted: Bool {
        currentGroup.allSatisfy { completedWords.contains($0.id) }
    }
    
    // 获取当前组的错误数
    var currentGroupErrorCount: Int {
        incorrectAnswers.count
    }
    
    // 重置当前组
    mutating func resetCurrentGroup() {
        completedWords.removeAll()
        incorrectAnswers.removeAll()
    }
    
    // 移动到下一组
    mutating func moveToNextGroup() {
        // 1. 确保有足够的单词可以移除
        guard currentWords.count >= wordsPerGroup else { return }
        
        // 2. 移除当前组的单词
        currentWords.removeFirst(min(wordsPerGroup, currentWords.count))
        
        // 3. 清除当前组的状态（只需要这一次清除）
        resetCurrentGroup()
    }
    
    // 检查整个练习是否完成
    var isSessionComplete: Bool {
        currentWords.isEmpty || (currentWords.count <= wordsPerGroup && isGroupCompleted)
    }
    
    // 获取错误的单词
    var incorrectWords: [WordEntry] {
        currentGroup.filter { incorrectAnswers.contains($0.id) }
    }
}
