import XCTest
@testable import memo

final class PracticeSessionTests: XCTestCase {
    var practiceSession: PracticeSession!
    var testEntries: [WordEntry]!
    
    override func setUp() {
        super.setUp()
        testEntries = [
            WordEntry(word: "hello", sentence: "Hello world"),
            WordEntry(word: "test", sentence: "This is a test"),
            WordEntry(word: "apple", sentence: "I eat an apple")
        ]
        practiceSession = PracticeSession(words: testEntries, wordsPerGroup: 3)
    }
    
    func testInitialization() {
        XCTAssertEqual(practiceSession.currentGroup.count, 3)
        XCTAssertEqual(practiceSession.wordsPerGroup, 3)
        XCTAssertFalse(practiceSession.isReadAloudEnabled)
    }
    
    func testCheckAnswer() {
        let firstWord = practiceSession.currentGroup[0]
        
        // Test correct answer
        XCTAssertTrue(practiceSession.checkAnswer(wordId: firstWord.id, answer: firstWord.word))
        
        // Test incorrect answer
        XCTAssertFalse(practiceSession.checkAnswer(wordId: firstWord.id, answer: "wrong"))
    }
    
    func testGroupCompletion() {
        // Initially not completed
        XCTAssertFalse(practiceSession.isGroupCompleted)
        
        // Complete all words
        for entry in practiceSession.currentGroup {
            _ = practiceSession.checkAnswer(wordId: entry.id, answer: entry.word)
        }
        
        // Should be completed now
        XCTAssertTrue(practiceSession.isGroupCompleted)
    }
    
    func testMoveToNextGroup() {
        // 创建足够多的测试数据
        testEntries = [
            WordEntry(word: "hello", sentence: "Hello world"),
            WordEntry(word: "test", sentence: "This is a test"),
            WordEntry(word: "apple", sentence: "I eat an apple"),
            WordEntry(word: "book", sentence: "I read a book"),
            WordEntry(word: "cat", sentence: "The cat sleeps"),
            WordEntry(word: "dog", sentence: "The dog barks")
        ]
        practiceSession = PracticeSession(words: testEntries, wordsPerGroup: 3)
        
        let initialFirstWord = practiceSession.currentGroup[0]
        practiceSession.moveToNextGroup()
        
        // 确保还有下一组单词
        XCTAssertFalse(practiceSession.currentGroup.isEmpty)
        XCTAssertNotEqual(practiceSession.currentGroup[0].id, initialFirstWord.id)
    }
    
    func testIncorrectWordsTracking() {
        let firstWord = practiceSession.currentGroup[0]
        
        // Submit wrong answer
        _ = practiceSession.checkAnswer(wordId: firstWord.id, answer: "wrong")
        
        // Verify incorrect words tracking
        XCTAssertEqual(practiceSession.incorrectWords.count, 1)
        XCTAssertEqual(practiceSession.incorrectWords.first?.id, firstWord.id)
    }

    func testResetCurrentGroup() {
        let firstWord = practiceSession.currentGroup[0]
        _ = practiceSession.checkAnswer(wordId: firstWord.id, answer: "wrong")
        
        practiceSession.resetCurrentGroup()
        XCTAssertEqual(practiceSession.currentGroupErrorCount, 0)
        XCTAssertFalse(practiceSession.isGroupCompleted)
    }

    func testSessionCompletion() {
        // 完成所有单词
        for entry in practiceSession.currentGroup {
            _ = practiceSession.checkAnswer(wordId: entry.id, answer: entry.word)
        }
        
        // 移动到下一组
        practiceSession.moveToNextGroup()
        
        // 如果没有更多单词，应该显示完成
        if practiceSession.currentGroup.isEmpty {
            XCTAssertTrue(practiceSession.isSessionComplete)
        }
    }
}
