import XCTest
@testable import memo

final class VocabularyListSortTests: XCTestCase {
    var list: VocabularyList!
    var entries: [WordEntry]!
    
    override func setUp() {
        super.setUp()
        list = VocabularyList(name: "Test List")
        entries = [
            WordEntry(word: "apple", sentence: "I eat an apple"),
            WordEntry(word: "banana", sentence: "The banana is yellow"),
            WordEntry(word: "cat", sentence: "The cat sleeps")
        ]
        list.entries = entries
    }
    
    func testAlphabeticalSorting() {
        let sorted = list.sortedEntries(by: .alphabetical, ascending: true)
        XCTAssertEqual(sorted.map { $0.word }, ["apple", "banana", "cat"])
        
        let sortedDesc = list.sortedEntries(by: .alphabetical, ascending: false)
        XCTAssertEqual(sortedDesc.map { $0.word }, ["cat", "banana", "apple"])
    }
    
    func testDateSorting() {
        // Create entries with different dates
        var entries = [WordEntry]()
        for i in 0..<3 {
            var entry = WordEntry(word: "word\(i)", sentence: "sentence \(i)")
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                entry.createdAt = date
            }
            entries.append(entry)
        }
        
        // 更新 list 的 entries
        list.entries = entries
        
        let sorted = list.sortedEntries(by: .date, ascending: true)
        XCTAssertEqual(sorted.map { $0.word }, ["word2", "word1", "word0"])
    }

    func testErrorCountSorting() {
        // Create entries with different error counts
        var entries = [WordEntry]()
        for i in 0..<3 {
            var entry = WordEntry(word: "word\(i)", sentence: "sentence \(i)")
            entry.errorCount = i
            entries.append(entry)
        }
        
        // 更新 list 的 entries
        list.entries = entries
        
        let sorted = list.sortedEntries(by: .errorCount, ascending: true)
        XCTAssertEqual(sorted.map { $0.errorCount }, [0, 1, 2])
    }
} 
