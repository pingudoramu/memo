import XCTest
@testable import memo

final class WordEntryTimeTests: XCTestCase {
    func testReviewDateCalculation() {
        var entry = WordEntry(word: "test", sentence: "Test sentence")
        let calendar = Calendar.current
        
        // Test different levels
        let levels = [1, 2, 3, 4, 5, 6]
        let expectedDays = [1, 3, 7, 14, 30, 60]
        
        for (index, level) in levels.enumerated() {
            entry.level = level
            entry.updateNextReviewDate()
            
            let expectedDate = calendar.date(byAdding: .day, value: expectedDays[index], to: calendar.startOfDay(for: Date()))!
            XCTAssertEqual(
                calendar.startOfDay(for: entry.nextReviewDate),
                calendar.startOfDay(for: expectedDate),
                "Failed for level \(level)"
            )
        }
    }
    
    func testNeedsReview() {
        var entry = WordEntry(word: "test", sentence: "Test sentence")
        
        // New entry should need review
        XCTAssertTrue(entry.isFirstPractice)
        
        // After first practice
        entry.isFirstPractice = false
        entry.level = 1
        entry.updateNextReviewDate()
        
        // Should not need review immediately
        XCTAssertFalse(entry.needsReview)
        
        // Set next review date to yesterday
        let calendar = Calendar.current
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) {
            entry.nextReviewDate = yesterday
            XCTAssertTrue(entry.needsReview)
        }
    }
    func testReviewScheduling() {
        var entry = WordEntry(word: "test", sentence: "Test sentence")
        
        // 测试首次练习标记
        XCTAssertTrue(entry.isFirstPractice)
        
        // 测试复习时间更新
        entry.isFirstPractice = false
        entry.level = 2
        entry.updateNextReviewDate()
        
        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: Date()))!
        XCTAssertEqual(
            calendar.startOfDay(for: entry.nextReviewDate),
            calendar.startOfDay(for: expectedDate)
        )
    }
} 
