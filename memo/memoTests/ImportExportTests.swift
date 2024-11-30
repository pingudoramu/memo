import XCTest
@testable import memo

final class ImportExportTests: XCTestCase {
    var viewModel: WordListViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = WordListViewModel()
    }
    
    func testExportList() {
        // Create a list with some entries
        viewModel.createList(name: "Test List")
        guard let listId = viewModel.wordLists.first?.id else {
            XCTFail("Failed to create list")
            return
        }
        
        let entry = WordEntry(word: "test", sentence: "This is a test")
        viewModel.addWordEntry(entry, to: listId)
        
        // Export
        let exported = viewModel.exportLists()
        XCTAssertFalse(exported.isEmpty)
        
        // Verify CSV format
        let firstExport = exported.first
        XCTAssertNotNil(firstExport)
        XCTAssertTrue(firstExport?.fileName.hasSuffix(".csv") ?? false)
        XCTAssertTrue(firstExport?.csvData.contains("Word;Sentence") ?? false)
        XCTAssertTrue(firstExport?.csvData.contains("test;\"This is a test\"") ?? false)
    }
} 
