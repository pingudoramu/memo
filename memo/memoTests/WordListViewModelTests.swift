import XCTest
@testable import memo

final class WordListViewModelTests: XCTestCase {
    var viewModel: WordListViewModel!
    
    override func setUp() {
        super.setUp()
        // 清除 UserDefaults 中的数据
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        viewModel = WordListViewModel()
        // 确保初始状态是空的
        viewModel.wordLists.removeAll()
    }
    
    override func tearDown() {
        // 测试结束后清理
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        super.tearDown()
    }
    
    func testCreateList() {
        viewModel.createList(name: "Test List")
        XCTAssertEqual(viewModel.wordLists.count, 1)
        XCTAssertEqual(viewModel.wordLists.first?.name, "Test List")
    }
    
    func testAddWordEntry() {
        // First create a list
        viewModel.createList(name: "Test List")
        guard let listId = viewModel.wordLists.first?.id else {
            XCTFail("Failed to create list")
            return
        }
        
        // Add word entry
        let entry = WordEntry(word: "test", sentence: "This is a test")
        viewModel.addWordEntry(entry, to: listId)
        
        XCTAssertEqual(viewModel.wordLists.first?.entries.count, 1)
        XCTAssertEqual(viewModel.wordLists.first?.entries.first?.word, "test")
    }
    
    func testDeleteEntry() {
        // Setup
        viewModel.createList(name: "Test List")
        guard let listId = viewModel.wordLists.first?.id else {
            XCTFail("Failed to create list")
            return
        }
        
        let entry = WordEntry(word: "test", sentence: "This is a test")
        viewModel.addWordEntry(entry, to: listId)
        
        // Test deletion
        guard let entryId = viewModel.wordLists.first?.entries.first?.id else {
            XCTFail("Failed to add entry")
            return
        }
        
        viewModel.deleteEntry(entryId, from: listId)
        XCTAssertTrue(viewModel.wordLists.first?.entries.isEmpty ?? false)
    }
    func testLevelManagement() {
        // 创建列表和单词
        viewModel.createList(name: "Test List")
        guard let listId = viewModel.wordLists.first?.id else {
            XCTFail("Failed to create list")
            return
        }
        let entry = WordEntry(word: "test", sentence: "This is a test")
        viewModel.addWordEntry(entry, to: listId)
        guard let entryId = viewModel.wordLists.first?.entries.first?.id else {
            XCTFail("Failed to add entry")
            return
        }
        
        // 测试等级增加
        viewModel.incrementLevel(for: entryId, in: listId)
        XCTAssertEqual(viewModel.wordLists.first?.entries.first?.level, 2)
        
        // 测试等级上限
        for _ in 0..<10 {
            viewModel.incrementLevel(for: entryId, in: listId)
        }
        XCTAssertEqual(viewModel.wordLists.first?.entries.first?.level, 6)
        
        // 测试等级减少
        viewModel.decrementLevel(for: entryId, in: listId)
        XCTAssertEqual(viewModel.wordLists.first?.entries.first?.level, 5)
        
        // 测试等级下限
        for _ in 0..<10 {
            viewModel.decrementLevel(for: entryId, in: listId)
        }
        XCTAssertEqual(viewModel.wordLists.first?.entries.first?.level, 1)
    }

    func testErrorCountTracking() {
        // 创建列表和单词
        viewModel.createList(name: "Test List")
        guard let listId = viewModel.wordLists.first?.id else {
            XCTFail("Failed to create list")
            return
        }
        let entry = WordEntry(word: "test", sentence: "This is a test")
        viewModel.addWordEntry(entry, to: listId)
        guard let entryId = viewModel.wordLists.first?.entries.first?.id else {
            XCTFail("Failed to add entry")
            return
        }
        
        // 测试错误计数增加
        viewModel.updateErrorCount(for: entryId, in: listId)
        XCTAssertEqual(viewModel.wordLists.first?.entries.first?.errorCount, 1)
        
        // 测试多次错误
        viewModel.updateErrorCount(for: entryId, in: listId)
        XCTAssertEqual(viewModel.wordLists.first?.entries.first?.errorCount, 2)
    }
} 
