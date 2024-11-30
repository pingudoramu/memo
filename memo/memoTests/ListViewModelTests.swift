import XCTest
@testable import memo

final class ListViewModelTests: XCTestCase {
    var viewModel: ListViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = ListViewModel()
    }
    
    func testDefaultListCreation() {
        XCTAssertEqual(viewModel.lists.count, 1)
        XCTAssertTrue(viewModel.lists[0].isDefault)
        XCTAssertEqual(viewModel.lists[0].name, "default")
    }
    
    func testAddList() {
        viewModel.addList(name: "Test List")
        XCTAssertEqual(viewModel.lists.count, 2)
        XCTAssertEqual(viewModel.lists[1].name, "Test List")
        XCTAssertFalse(viewModel.lists[1].isDefault)
    }
    
    func testAddWordToList() {
        let listId = viewModel.lists[0].id
        viewModel.addWord(word: "test", sentence: "This is a test", toListId: listId)
        
        XCTAssertEqual(viewModel.lists[0].entries.count, 1)
        XCTAssertEqual(viewModel.lists[0].entries[0].word, "test")
        XCTAssertEqual(viewModel.lists[0].entries[0].sentence, "This is a test")
    }
} 
