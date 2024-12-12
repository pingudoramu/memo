import SwiftUI

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

struct PracticeView: View {
    @ObservedObject var viewModel: WordListViewModel
    @Environment(\.dismiss) private var dismiss

    let listId: UUID?
    let sortOption: SortOption
    let entries: [WordEntry]?
    
    @State private var currentGroupIndex = 0
    @State private var droppedWords: [Int: String] = [:]
    @State private var showingResult = false
    @State private var incorrectIndices: Set<Int> = []
    @AppStorage("wordsPerGroup") private var wordsPerGroup: Int = 3
    @AppStorage("readAloudEnabled") private var readAloudEnabled: Bool = false
    
    // 记录每个单词的正确和错误次数
    @State private var wordResults: [UUID: [Bool]] = [:]  // 存储每个单词的所有尝试结果
    
    // 添加一个存储所有练习单词的属性
    private let allPracticeEntries: [WordEntry]
    
    @State private var shuffledWords: [String] = []
    
 
    
    
    private var currentList: VocabularyList? {
        viewModel.wordLists.first(where: { $0.id == listId })
    }
    
    private var currentEntries: [WordEntry] {
        let startIndex = currentGroupIndex * wordsPerGroup
        return Array(allPracticeEntries.dropFirst(startIndex).prefix(wordsPerGroup))
    }
    

    
    private var sentences: [String] {
        currentEntries.map { $0.sentenceWithBlank }
    }
    
    private func getSentenceWithDroppedWord(_ sentence: String, index: Int) -> AttributedString {
        if let droppedWord = droppedWords[index] {
            let newSentence = sentence.replacingOccurrences(of: "______", with: droppedWord)
            var attributedString = AttributedString(newSentence)
            
            let wordPattern = "\\b\(NSRegularExpression.escapedPattern(for: droppedWord))\\b"
            if let regex = try? NSRegularExpression(pattern: wordPattern, options: [.caseInsensitive]) {
                let nsRange = NSRange(newSentence.startIndex..., in: newSentence)
                let results = regex.matches(in: newSentence, options: [], range: nsRange)
                
                for result in results {
                    if let range = Range(result.range, in: newSentence),
                       let attributedRange = AttributedString.Index(range.lowerBound, within: attributedString)
                        .flatMap({ lower in
                            AttributedString.Index(range.upperBound, within: attributedString)
                                .map({ upper in lower..<upper })
                        }) {
                        attributedString[attributedRange].foregroundColor = .themeColor
                        attributedString[attributedRange].font = .system(.body, design: .rounded).bold()

                    }
                }
            }
            return attributedString
        }
        return AttributedString(sentence)
    }
    
    private var totalGroups: Int {
        Int(ceil(Double(allPracticeEntries.count) / Double(wordsPerGroup)))
    }
    
    private func checkAnswers() -> Bool {
        incorrectIndices.removeAll()
        
        for (index, entry) in currentEntries.enumerated() {
            if let droppedWord = droppedWords[index] {
                let isCorrect = droppedWord == entry.wordToFill
                if !isCorrect {
                    incorrectIndices.insert(index)
                }
                
                // 检查这个单词是否是第一次提交
                let isFirstSubmitForThisWord = wordResults[entry.id] == nil
                
                // 只在这个单词的第一次 submit 时记录结果
                if isFirstSubmitForThisWord {
                    wordResults[entry.id] = []
                    wordResults[entry.id]?.append(isCorrect)
                }
            } else {
                incorrectIndices.insert(index)
                
                // 检查这个单词是否是第一次提交
                let isFirstSubmitForThisWord = wordResults[entry.id] == nil
                
                if isFirstSubmitForThisWord {
                    wordResults[entry.id] = []
                    wordResults[entry.id]?.append(false)
                }
            }
        }
        
        return incorrectIndices.isEmpty
    }
 

    
    private func moveToNextGroup() {
        currentGroupIndex += 1
        droppedWords.removeAll()
        incorrectIndices.removeAll()
        
        let startIndex = currentGroupIndex * wordsPerGroup
        shuffledWords = Array(allPracticeEntries.dropFirst(startIndex).prefix(wordsPerGroup))
            .map { $0.word }
            .shuffled()
        
    }
    
    private func retryIncorrectOnly() {
        let correctAnswers = droppedWords.filter { !incorrectIndices.contains($0.key) }
        droppedWords = correctAnswers
    }
    
    private func resetCurrentGroup() {
        droppedWords.removeAll()
        incorrectIndices.removeAll()
    }
    
    init(viewModel: WordListViewModel, listId: UUID? = nil, sortOption: SortOption = .latestDate, entries: [WordEntry]? = nil) {
        self.viewModel = viewModel
        self.listId = listId
        self.sortOption = sortOption
        
        if let entries = entries {
            self.allPracticeEntries = entries
        } else if let list = viewModel.wordLists.first(where: { $0.id == listId }) {
            self.allPracticeEntries = list.sortedEntries(
                by: sortOption.criterion,
                ascending: sortOption.isAscending,
                randomSeed: UUID()
            )
        } else {
            self.allPracticeEntries = []
        }
        
        self.entries = entries
        
        _shuffledWords = State(initialValue: Array(self.allPracticeEntries.prefix(wordsPerGroup)).map { $0.word }.shuffled())
     }
    
    // 在完成所有练习后更新
    private func updateAllResults() {
        for (wordId, results) in wordResults {
            if let listId = listId ?? viewModel.getListId(for: wordId) {
                if let entry = viewModel.wordLists.first(where: { $0.id == listId })?
                    .entries.first(where: { $0.id == wordId }) {
                    
                    // 如果是首次练习，或者已经到了复习时间
                    if entry.isFirstPractice || Date() >= entry.nextReviewDate {
                        // 添加练习结果到历史记录
                        for result in results {
                            // 修改这里：直接在 entry 上修改，然后一次性保存
                            if let listIndex = viewModel.wordLists.firstIndex(where: { $0.id == listId }),
                               let entryIndex = viewModel.wordLists[listIndex].entries.firstIndex(where: { $0.id == wordId }) {  // 这里改用 wordId
                                var updatedEntry = viewModel.wordLists[listIndex].entries[entryIndex]
                                updatedEntry.addPracticeResult(result)
                                viewModel.wordLists[listIndex].entries[entryIndex] = updatedEntry
                            }
                        }
                        
                        // 获取更新后的 entry
                        if let updatedEntry = viewModel.wordLists.first(where: { $0.id == listId })?
                            .entries.first(where: { $0.id == wordId }) {
                            
                            // 1. 检查是否需要降级（连续错误 >= 3）
                            if updatedEntry.consecutiveErrors >= 3 {
                                viewModel.setLevel(for: wordId, in: listId, to: 1)
                            }
                            // 2. 检查是否需要降一级（连续错误 = 2）
                            else if updatedEntry.consecutiveErrors == 2 {
                                viewModel.decrementLevel(for: wordId, in: listId)
                            }
                            // 3. 检查是否可以升级（连续正确 >= 2）
                            else if updatedEntry.consecutiveCorrects >= 2 {
                                viewModel.incrementLevel(for: wordId, in: listId)
                            }
                            
                            // 更新首次练习标记和复习日期
                            if entry.isFirstPractice {
                                viewModel.setFirstPracticeDone(for: wordId, in: listId)
                            } else {
                                viewModel.updateReviewDate(for: wordId, in: listId)
                            }
                        }
                    }
                    
                    // 错误计数总是更新
                    if results.contains(false) {
                        viewModel.updateErrorCount(for: wordId, in: listId)
                    }
                }
            }
        }
    }
    
        

    
    var body: some View {
        VStack(spacing: 20) {

            
            // Practice sentences 句子
            ScrollView {
                VStack(spacing: 0) {  // 改为 0 来完全控制间距
                    ForEach(Array(sentences.enumerated()), id: \.offset) { index, sentence in
                        VStack(spacing: 0) {  // 内部 VStack 也改为 0
                            Text(getSentenceWithDroppedWord(sentence, index: index))
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(Color(UIColor.darkGray))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 15)  // 匹配 ListView 的 top/bottom padding
                                .padding(.horizontal, 20)  // 匹配 ListView 的 leading/trailing padding
                                .textSelection(.enabled) 
                                .onTapGesture {
                                    if readAloudEnabled {
                                        SpeechService.shared.speak(currentEntries[index].sentence)
                                    }
                                }
                                .dropDestination(for: String.self) { items, _ in
                                    guard let droppedWord = items.first else { return false }
                                    // 找到对应的 entry
                                    if let entry = currentEntries[safe: index] {
                                        // 如果拖入的是原形，存储对应的变化形式
                                        if droppedWord == entry.word {
                                            droppedWords[index] = entry.wordToFill
                                        }
                                    }
                                    return true
                                }
                            
                            if index < sentences.count - 1 {
                                Divider()
                                    .frame(maxWidth: .infinity)
                                    .padding(.leading, 20)  // 只在左侧添加 20 点的边距
                            }
                        }
                    }
                }
            }
            
            
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            
            // Word options
            VStack {  // 添加这个 VStack
                Spacer()  // 上方空白
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                    ForEach(shuffledWords, id: \.self) { word in
                        Text(word)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.themeColor)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.themeColor)
                            )
                            .opacity(droppedWords.values.contains(word) ? 0.5 : 1) 
                            .draggable(word)
                            .onTapGesture {
                                if readAloudEnabled {
                                    SpeechService.shared.speak(word)
                                }
                            }
                    }
                }
//                Spacer()  // 下方空白
            }
            .padding(.horizontal)
                       .frame(maxHeight: CGFloat(ceil(Double(shuffledWords.count) / 3.0)) * 40) // 根据单词数量动态计算高度
                       
            
            // Submit button
            Button(action: {
                _ = checkAnswers()
                showingResult = true
            }) {
                Text("Submit")
                    .font(.system(.headline, design: .rounded)).bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themeColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 10)

        }
        .navigationTitle("Group \(currentGroupIndex + 1)/\(totalGroups)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    resetCurrentGroup()
                }) {
                    Text("Reset")
                        .foregroundColor(.orange)
                        .font(.system(.body, design: .rounded))
                }
            }
        }
        .alert("Practice Result", isPresented: $showingResult) {
            if !incorrectIndices.isEmpty {
                Button("Retry All") {
                    resetCurrentGroup()
                }
                Button("Retry Incorrect") {
                    retryIncorrectOnly()
                }
            } else {
                Button("Retry") {
                    resetCurrentGroup()
                }
                if currentGroupIndex < totalGroups - 1 {
                    Button("Next Group") {
                        moveToNextGroup()
                    }
                } else {
                    Button("Done") {
                        updateAllResults()  // 在最后统一更新
                        dismiss()
                    }
                }
            }
        } message: {
            if incorrectIndices.isEmpty {
                Text("Perfect! All answers are correct!")
            } else {
                Text("You have \(incorrectIndices.count) incorrect answers.")
            }
        }
        .onDisappear {
            // 如果有任何练习记录，在离开界面时保存
            if !wordResults.isEmpty {
                updateAllResults()
            }
        }
    }
    
    // 计算连续错误次数
    private func calculateConsecutiveErrors(_ results: [Bool]) -> Int {
        var maxConsecutiveErrors = 0
        var currentConsecutiveErrors = 0
        
        for result in results {
            if !result {
                currentConsecutiveErrors += 1
                maxConsecutiveErrors = max(maxConsecutiveErrors, currentConsecutiveErrors)
            } else {
                currentConsecutiveErrors = 0
            }
        }
        
        return maxConsecutiveErrors
    }
    
    // 计算连续正确次数的方法
    private func calculateConsecutiveCorrects(_ results: [Bool]) -> Int {
        var currentConsecutiveCorrects = 0
        
        // 从后往前遍历，计算最近的连续正确次数
        for result in results.reversed() {
            if result {
                currentConsecutiveCorrects += 1
            } else {
                break  // 遇到错误就停止计数
            }
        }
        
        return currentConsecutiveCorrects
    }

}
