import XCTest
@testable import memo

final class WordEntryTests: XCTestCase {
    func testWordEntryInitialization() {
        // Test basic initialization
        let entry = WordEntry(word: "hello", sentence: "Hello world")
        XCTAssertEqual(entry.word, "hello")
        XCTAssertEqual(entry.sentence, "Hello world")
        XCTAssertEqual(entry.errorCount, 0)
        XCTAssertEqual(entry.level, 1)
        XCTAssertTrue(entry.isFirstPractice)
    }
    
    func testWordValidation() {
        // Test valid cases
        XCTAssertTrue(WordEntry.validate(word: "hello", sentence: "Hello world"))
        XCTAssertTrue(WordEntry.validate(word: "Hello", sentence: "Hello world"))
        
        // Test invalid cases
        XCTAssertFalse(WordEntry.validate(word: "", sentence: "Hello world"))
        XCTAssertFalse(WordEntry.validate(word: "hello", sentence: ""))
        XCTAssertFalse(WordEntry.validate(word: "hello", sentence: "Good morning"))
    }
    
    func testSentenceWithBlank() {
        let entry = WordEntry(word: "hello", sentence: "Hello world")
        XCTAssertEqual(entry.sentenceWithBlank, "______ world")
        
        let entry2 = WordEntry(word: "the", sentence: "The cat and the dog")
        XCTAssertEqual(entry2.sentenceWithBlank, "______ cat and ______ dog")
    }
    
    func testNextReviewDateCalculation() {
        let entry = WordEntry(word: "test", sentence: "Test sentence")
        var mutableEntry = entry
        
        // Test level 1 review date (1 day)
        mutableEntry.level = 1
        mutableEntry.updateNextReviewDate()
        let calendar = Calendar.current
        let expectedDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        XCTAssertEqual(calendar.startOfDay(for: mutableEntry.nextReviewDate),
                      calendar.startOfDay(for: expectedDate))
    }
    
    func testWordFormMatching() {
        // Test different word forms
        let testCases = [
            // 过去式
            (word: "play", sentence: "I played football", shouldMatch: true),
            // 现在进行时
            (word: "play", sentence: "I am playing football", shouldMatch: true),
            // 第三人称单数
            (word: "play", sentence: "He plays football", shouldMatch: true),
            // 不相关的词
            (word: "play", sentence: "I watched football", shouldMatch: false),
            // 复数形式
            (word: "dog", sentence: "I have two dogs", shouldMatch: true),
            // 比较级
            (word: "big", sentence: "This is bigger", shouldMatch: true),
            // 最高级
            (word: "big", sentence: "This is the biggest", shouldMatch: true)
        ]
        
        for testCase in testCases {
            XCTAssertEqual(
                WordEntry.validate(word: testCase.word, sentence: testCase.sentence),
                testCase.shouldMatch,
                "Failed for word: \(testCase.word) in sentence: \(testCase.sentence)"
            )
        }
    }
        func testDisplaySentence() {
            // 测试高亮显示
            let entry = WordEntry(word: "test", sentence: "This is a test case")
            let attributedString = entry.displaySentence
            
            // 验证高亮单词存在
            XCTAssertTrue(attributedString.runs.contains { run in
                run.attributes.foregroundColor == .themeColor
            })
            
            // 测试多个匹配
            let entry2 = WordEntry(word: "the", sentence: "The cat and the dog")
            let attributedString2 = entry2.displaySentence
            let greenRuns = attributedString2.runs.filter { run in
                run.attributes.foregroundColor == .themeColor
            }
            XCTAssertEqual(greenRuns.count, 2) // 应该有两处高亮
        }

        func testEndingWithE() {
            let testCases = [
                // 以 e 结尾的动词
                (word: "like", sentence: "I liked the movie", shouldMatch: true),
                (word: "like", sentence: "I am liking this", shouldMatch: true),
                (word: "move", sentence: "He moved away", shouldMatch: true),
                (word: "move", sentence: "He is moving", shouldMatch: true),
                // 其他以 e 结尾的常见动词
                (word: "make", sentence: "She made a cake", shouldMatch: true),
                (word: "make", sentence: "She is making dinner", shouldMatch: true),
                (word: "take", sentence: "I took the bus", shouldMatch: true),
                (word: "take", sentence: "I am taking a break", shouldMatch: true)
            ]
            
            for testCase in testCases {
                XCTAssertEqual(
                    WordEntry.validate(word: testCase.word, sentence: testCase.sentence),
                    testCase.shouldMatch,
                    "Failed for word: \(testCase.word) in sentence: \(testCase.sentence)"
                )
            }
        }

        func testCaseInsensitivity() {
            let testCases = [
                // 测试大小写不敏感
                (word: "Test", sentence: "This is a test", shouldMatch: true),
                (word: "test", sentence: "This is a Test", shouldMatch: true),
                (word: "TEST", sentence: "This is a test", shouldMatch: true),
                (word: "test", sentence: "This is a TEST", shouldMatch: true),
                // 测试变化形式的大小写
                (word: "Play", sentence: "He PLAYED football", shouldMatch: true),
                (word: "STOP", sentence: "He stopped the car", shouldMatch: true)
            ]
            
            for testCase in testCases {
                XCTAssertEqual(
                    WordEntry.validate(word: testCase.word, sentence: testCase.sentence),
                    testCase.shouldMatch,
                    "Failed for word: \(testCase.word) in sentence: \(testCase.sentence)"
                )
            }
        }

    func testInvalidInput() {
        // 测试空输入
        XCTAssertFalse(WordEntry.validate(word: "", sentence: ""),
            "Should reject empty word and sentence")
        XCTAssertFalse(WordEntry.validate(word: "test", sentence: ""),
            "Should reject empty sentence")
        XCTAssertFalse(WordEntry.validate(word: "", sentence: "test"),
            "Should reject empty word")
        
        // 测试单词不在句子中的情况
        XCTAssertFalse(WordEntry.validate(word: "apple", sentence: "The banana is yellow."),
            "Should reject word that is not in the sentence")
        
        // 测试只有空格的情况
        XCTAssertFalse(WordEntry.validate(word: "   ", sentence: "   "),
            "Should reject whitespace-only input")
        

        // 可以再添加一些相关的测试用例
        XCTAssertTrue(WordEntry.validate(word: "cat", sentence: "The cats are playing."),
            "Should accept word's plural form")
        XCTAssertFalse(WordEntry.validate(word: "cat", sentence: "The caterpillar is crawling."),
            "Should reject word that is part of an unrelated word")
    }

    func testConcurrentAccess() {
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 100  // 期望执行100次
        
        let queue = DispatchQueue(label: "test.queue", attributes: .concurrent)
        let group = DispatchGroup()
        
        // 创建一个共享的 WordEntry 实例
        let entry = WordEntry(word: "test", sentence: "This is a test")
        
        // 并发访问
        for _ in 0..<100 {
            group.enter()
            queue.async(group: group) {
                // 执行一些并发操作
                _ = entry.sentenceWithBlank
                _ = entry.displaySentence
                _ = WordEntry.validate(word: entry.word, sentence: entry.sentence)
                
                expectation.fulfill()
                group.leave()
            }
        }
        
        // 等待所有操作完成
        wait(for: [expectation], timeout: 5.0)
        
        // 验证结果
        XCTAssertEqual(entry.word, "test")  // 确保原始数据没有被修改
        XCTAssertEqual(entry.sentence, "This is a test")
    }
    func testAdverbVariations() {
        let testCases = [
            // 基本 -ly 形式
            (word: "quick", sentence: "He ran quickly", shouldMatch: true),
            // -ing + ly 形式
            (word: "strike", sentence: "It was strikingly beautiful", shouldMatch: true),
            (word: "striking", sentence: "It was strikingly beautiful", shouldMatch: true),
            // 双写辅音字母 + ing + ly
            (word: "stun", sentence: "It was stunningly good", shouldMatch: true),
            (word: "stunning", sentence: "It was stunningly good", shouldMatch: true),
            // 不相关的词
            (word: "quick", sentence: "He ran fast", shouldMatch: false)
        ]
        
        for testCase in testCases {
            XCTAssertEqual(
                WordEntry.validate(word: testCase.word, sentence: testCase.sentence),
                testCase.shouldMatch,
                "Failed for word: \(testCase.word) in sentence: \(testCase.sentence)"
            )
        }

        func testPhraseValidation() {
            let testCases = [
                // 基本词组测试
                (word: "look up", sentence: "I need to look up this word", shouldMatch: true),
                (word: "look up", sentence: "I looked up the word", shouldMatch: true),
                (word: "look up", sentence: "Looking up words is important", shouldMatch: true),
                
                // 带介词的词组
                (word: "get along with", sentence: "I get along with my neighbors", shouldMatch: true),
                (word: "get along with", sentence: "He gets along with everyone", shouldMatch: true),
                (word: "get along with", sentence: "They are getting along with each other", shouldMatch: true),
                
                // 固定搭配
                (word: "as soon as", sentence: "I'll call you as soon as I arrive", shouldMatch: true),
                (word: "as soon as", sentence: "As soon as possible", shouldMatch: true),
                
                // 不完整匹配测试
                (word: "look up", sentence: "I look at the sky up there", shouldMatch: false),
                (word: "get along with", sentence: "I get this along", shouldMatch: false),
                
                // 大小写测试
                (word: "Look Up", sentence: "I need to look up this word", shouldMatch: true),
                (word: "look up", sentence: "I need to Look Up this word", shouldMatch: true),
                
                // 词组中间有额外空格
                (word: "look   up", sentence: "I need to look up this word", shouldMatch: true),
                
                // 部分匹配测试
                (word: "look up", sentence: "lookup process", shouldMatch: false),
                (word: "get along with", sentence: "getting along", shouldMatch: false)
            ]
            
            for testCase in testCases {
                XCTAssertEqual(
                    WordEntry.validate(word: testCase.word, sentence: testCase.sentence),
                    testCase.shouldMatch,
                    "Failed for phrase: '\(testCase.word)' in sentence: '\(testCase.sentence)'"
                )
            }
        }

        func testPhraseSentenceWithBlank() {
            let testCases = [
                // 基本词组替换
                (word: "look up", sentence: "I need to look up this word", expected: "I need to ______ this word"),
                (word: "get along with", sentence: "I get along with my neighbors", expected: "I ______ my neighbors"),
                
                // 多次出现的词组
                (word: "as soon as", sentence: "As soon as he arrives, call me as soon as possible",
                 expected: "______ he arrives, call me ______ possible"),
                
                // 包含标点符号
                (word: "look up", sentence: "Look up this word, then look up that word.",
                 expected: "______ this word, then ______ that word."),
            ]
            
            for testCase in testCases {
                let entry = WordEntry(word: testCase.word, sentence: testCase.sentence)
                XCTAssertEqual(
                    entry.sentenceWithBlank,
                    testCase.expected,
                    "Failed for phrase: '\(testCase.word)' in sentence: '\(testCase.sentence)'"
                )
            }
        }

        func testPhraseDisplaySentence() {
            let testCases = [
                ("look up", "I need to look up this word"),
                ("get along with", "I get along with my neighbors"),
                ("as soon as", "Call me as soon as possible")
            ]
            
            for (phrase, sentence) in testCases {
                let entry = WordEntry(word: phrase, sentence: sentence)
                let attributedString = entry.displaySentence
                
                // 验证高亮部分存在
                let highlightedRuns = attributedString.runs.filter { run in
                    run.attributes.foregroundColor == .themeColor
                }
                
                XCTAssertTrue(highlightedRuns.count > 0,
                             "No highlighting found for phrase: '\(phrase)' in sentence: '\(sentence)'")
            }
        }

        func testPhraseInitialization() {
            let testCases = [
                // 基本初始化
                (word: "look up", sentence: "I need to look up this word"),
                // 带额外空格
                (word: "  look up  ", sentence: "  I need to look up this word  "),
                // 大小写混合
                (word: "Look Up", sentence: "I need to look up this word"),
                // 较长词组
                (word: "get along with", sentence: "I get along with my neighbors")
            ]
            
            for testCase in testCases {
                let entry = WordEntry(word: testCase.word, sentence: testCase.sentence)
                
                // 验证空格处理
                XCTAssertFalse(entry.word.hasPrefix(" "), "Word should not start with space")
                XCTAssertFalse(entry.word.hasSuffix(" "), "Word should not end with space")
                XCTAssertFalse(entry.sentence.hasPrefix(" "), "Sentence should not start with space")
                XCTAssertFalse(entry.sentence.hasSuffix(" "), "Sentence should not end with space")
                
                // 验证词组在句子中的存在
                XCTAssertTrue(
                    entry.sentence.lowercased().contains(entry.word.lowercased()),
                    "Phrase '\(entry.word)' not found in sentence '\(entry.sentence)'"
                )
            }
        }
        func testWordSplitting() {
            let testCases = [
                // 连字符词测试
                (word: "look-in", sentence: "I need a look-in at the situation", shouldMatch: true),
                (word: "check-up", sentence: "I had my check-up yesterday", shouldMatch: true),
                
                // 空格分隔的词组
                (word: "look up", sentence: "I need to look up this word", shouldMatch: true),
                (word: "get along with", sentence: "I get along with my neighbors", shouldMatch: true),
                
                // 混合情况
                (word: "up-to-date", sentence: "Keep your software up-to-date", shouldMatch: true),
                (word: "state-of-the-art", sentence: "This is a state-of-the-art facility", shouldMatch: true),
                
                // 确保连字符不被视为分隔符
                (word: "look-in", sentence: "I look in the box", shouldMatch: false),
                (word: "check-up", sentence: "I check up the details", shouldMatch: false),
                
                // 标点符号作为分隔符的情况
                (word: "look", sentence: "Look, it's beautiful", shouldMatch: true),
                (word: "look", sentence: "Look. It's beautiful", shouldMatch: true),
                (word: "look", sentence: "Look! It's beautiful", shouldMatch: true),
                
                // 连字符词的变化形式
                (word: "check-up", sentence: "Regular check-ups are important", shouldMatch: true),
                (word: "follow-up", sentence: "The follow-up meeting", shouldMatch: true)
            ]
            
            for testCase in testCases {
                XCTAssertEqual(
                    WordEntry.validate(word: testCase.word, sentence: testCase.sentence),
                    testCase.shouldMatch,
                    "Failed for word/phrase: '\(testCase.word)' in sentence: '\(testCase.sentence)'"
                )
            }
        }
    }
    }
