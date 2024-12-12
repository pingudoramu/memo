//
//  WordEntry.swift
//  memo
//
//  Created by mac on 2024/11/5.
//

import Foundation
import UIKit
import SwiftUI

struct WordEntry: Identifiable, Codable {
    var id: UUID
    let word: String
    let sentence: String
    var errorCount: Int
    var createdAt: Date
    var level: Int
    var lastReviewDate: Date
    var nextReviewDate: Date
    var isFirstPractice: Bool
    private var practiceHistory: [Bool] = []
    private let maxHistoryLength = 5
    private var actualWordForm: String?
    
    init(word: String, sentence: String) {
        self.id = UUID()
        // 确保去除多余空格
        self.word = word.trimmingCharacters(in: .whitespaces)
        self.sentence = sentence.trimmingCharacters(in: .whitespaces)
        // 删除重复的赋值
        self.errorCount = 0
        self.createdAt = Date()
        self.level = 1
        self.lastReviewDate = Date()
        
        // 新单词从第二天开始复习
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        self.nextReviewDate = tomorrow
        
        self.isFirstPractice = true
        
        // 在初始化时就找到并保存实际的单词形式
        let matches = findCompleteWordMatches(word, in: sentence)
        if let firstMatch = matches.first {
            self.actualWordForm = String(sentence[firstMatch])
        }
    }
    
    // For practice view - shows blank
    var sentenceWithBlank: String {
        var result = sentence
        let matches = findCompleteWordMatches(word, in: sentence)
        
        // 从后往前替换，以避免索引失效
        for range in matches.reversed() {
            result.replaceSubrange(range, with: "______")
        }
        return result
    }
    
    var wordToFill: String {
        return actualWordForm ?? word
    }
    
    var blankSentence: String {
        sentence.replacingOccurrences(of: word, with: "______", options: .caseInsensitive)
    }
    
    // For list view - shows highlighted word
    var displaySentence: AttributedString {
        var attributedString = AttributedString(sentence)
        attributedString.foregroundColor = Color(UIColor.darkGray)
        let matches = findCompleteWordMatches(word, in: sentence)
        
        for range in matches {
            if let attributedRange = AttributedString.Index(range.lowerBound, within: attributedString)
                .flatMap({ lower in
                    AttributedString.Index(range.upperBound, within: attributedString)
                        .map({ upper in lower..<upper })
                }) {
                attributedString[attributedRange].foregroundColor = .themeColor
                attributedString[attributedRange].font = .system(.body, design: .rounded).bold()

            }
        }
        return attributedString
    }
    
    // 辅助函数：找出所有匹配的完整单词位置
    // 添加不规则动词映射表
    private static let irregularVerbs: [String: Set<String>] = [
         "run": ["ran", "running", "runs"],
         "go": ["went", "going", "goes", "gone"],
         "eat": ["ate", "eating", "eats", "eaten"],
         "write": ["wrote", "writing", "writes", "written"],
         "read": ["reading", "reads"],  // read 过去式和原型相同
         "speak": ["spoke", "speaking", "speaks", "spoken"],
         "take": ["took", "taking", "takes", "taken"],
         "see": ["saw", "seeing", "sees", "seen"],
         "do": ["did", "doing", "does", "done"],
         "make": ["made", "making", "makes"],
         // 可以继续添加更多不规则动词
     ]
     
     // 修改 validate 方法
    static func validate(word: String, sentence: String) -> Bool {
        guard !word.isEmpty, !sentence.isEmpty else { return false }
        
        // 处理词组情况
        let wordPhrase = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 使用正则表达式匹配整个词组（包括连字符）
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: wordPhrase))\\b"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let nsRange = NSRange(sentence.startIndex..., in: sentence)
            if regex.firstMatch(in: sentence, options: [], range: nsRange) != nil {
                return true
            }
        }
        
        // 使用空格作为分隔符（不包括连字符）
        let words = wordPhrase.split { $0.isWhitespace }.map(String.init)
        
        // 如果是词组（包含多个由空格分隔的部分），需要完整匹配
        if words.count > 1 {
            return sentence.lowercased().contains(wordPhrase)
        }
        
         // 先检查不规则动词
         let wordLower = word.lowercased()
         if let irregularForms = irregularVerbs[wordLower] {
             let words = sentence.lowercased().components(separatedBy: .whitespaces)
             if words.contains(wordLower) || words.contains { irregularForms.contains($0) } {
                 return true
             }
         }
         
         // 如果不是不规则动词，使用词形还原
         let tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
         tagger.string = sentence
         
         let wordTagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
         wordTagger.string = word
         let wordLemma = wordTagger.tag(at: 0, scheme: .lemma, tokenRange: nil, sentenceRange: nil)?.rawValue ?? word
         
         var found = false
         let range = NSRange(location: 0, length: sentence.utf16.count)
         tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitPunctuation]) { tag, _, stop in
             if let lemma = tag?.rawValue, lemma == wordLemma {
                 found = true
                 stop.pointee = true
                 return
             }
         }
         
         // 如果词形还原也没找到，使用拼写规则
         if !found {
             let variations = getWordVariations(word)
             let pattern = "\\b(\(variations.joined(separator: "|")))\\b"
             if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                 let nsRange = NSRange(sentence.startIndex..., in: sentence)
                 found = regex.firstMatch(in: sentence, options: [], range: nsRange) != nil
             }
         }
         
         return found
     }
     
    // 同样修改 findCompleteWordMatches 方法
    private func findCompleteWordMatches(_ word: String, in text: String) -> [Range<String.Index>] {
        var matches: [Range<String.Index>] = []
         

        // 处理词组情况（包括连字符词）
        let wordPhrase = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 使用正则表达式匹配整个词组（包括连字符）
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: wordPhrase))\\b"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let nsRange = NSRange(text.startIndex..., in: text)
            let results = regex.matches(in: text, options: [], range: nsRange)
            
            for result in results {
                if let range = Range(result.range, in: text) {
                    matches.append(range)
                }
            }
            
            // 如果找到了完整匹配，直接返回
            if !matches.isEmpty {
                return matches
            }
        }
        
        // 使用空格作为分隔符（不包括连字符）
        let words = wordPhrase.split { $0.isWhitespace }.map(String.init)
        
        if words.count > 1 {
            // 对于词组，使用完整匹配
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: wordPhrase))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let nsRange = NSRange(text.startIndex..., in: text)
                let results = regex.matches(in: text, options: [], range: nsRange)
                
                for result in results {
                    if let range = Range(result.range, in: text) {
                        matches.append(range)
                    }
                }
            }
            return matches
            
         }
         
         // 如果不是不规则动词，使用原来的词形还原逻辑
         // 创建词形还原标记器
         let tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
         tagger.string = text
         
         // 获取原始单词的词根
         let wordTagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
         wordTagger.string = word
         let wordLemma = wordTagger.tag(at: 0, scheme: .lemma, tokenRange: nil, sentenceRange: nil)?.rawValue ?? word
         
         // 在句子中查找匹配
         let range = NSRange(location: 0, length: text.utf16.count)
         tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange, stop in
             if let lemma = tag?.rawValue,
                lemma == wordLemma,
                let range = Range(tokenRange, in: text) {
                 matches.append(range)
             }
         }
         
         // 如果没有找到词形还原匹配，回退到原始的精确匹配
         if matches.isEmpty {
             let variations = WordEntry.getWordVariations(word)
             let pattern = "\\b(\(variations.joined(separator: "|")))\\b"
             if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                 let nsRange = NSRange(text.startIndex..., in: text)
                 let results = regex.matches(in: text, options: [], range: nsRange)
                 
                 for result in results {
                     if let range = Range(result.range, in: text) {
                         matches.append(range)
                     }
                 }
             }
         }
         
         return matches
     }
     
     // 计算下次复习时间的方法 - 使用艾宾浩斯遗忘曲线的时间间隔
     
         mutating func updateNextReviewDate() {
             let calendar = Calendar.current
             let daysToAdd: Int

            switch level {
            case 1: daysToAdd = 1    // 第一天后复习
             case 2: daysToAdd = 3    // 3天后复习
             case 3: daysToAdd = 7    // 1周后复习
             case 4: daysToAdd = 14   // 2周后复习
             case 5: daysToAdd = 30   // 1个月后复习
             case 6: daysToAdd = 60   // 2个月后复习
             default: daysToAdd = 1
            }

                  lastReviewDate = Date()
                      let futureDate = calendar.date(byAdding: .day, value: daysToAdd, to: Date())!
                         nextReviewDate = calendar.startOfDay(for: futureDate)
              }

              
              // 新增：检查是否需要复习
              var needsReview: Bool {
                  let calendar = Calendar.current
                  let now = Date()
                  
                  // 比较日期部分，忽略具体时间
                  let nowDay = calendar.startOfDay(for: now)
                  let reviewDay = calendar.startOfDay(for: nextReviewDate)
                  
                  return nowDay >= reviewDay
              }

    
    // 添加新的练习结果
    mutating func addPracticeResult(_ isCorrect: Bool) {
        practiceHistory.append(isCorrect)
        if practiceHistory.count > maxHistoryLength {
            practiceHistory.removeFirst()
        }
    }

    // 获取连续正确次数
    var consecutiveCorrects: Int {
        var count = 0
        for result in practiceHistory.reversed() {
            if result {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    // 获取连续错误次数
    var consecutiveErrors: Int {
        var count = 0
        for result in practiceHistory.reversed() {
            if !result {
                count += 1
            } else {
                break
            }
        }
        return count
    }
    
    private static func getWordVariations(_ word: String) -> Set<String> {
        // 先将输入单词转换为小写
        let wordLower = word.lowercased()
        
        var variations = Set<String>()
        variations.insert(wordLower)  // 添加小写形式
        
        // 基本变化形式
        variations.insert(wordLower + "s")     // 第三人称单数
        variations.insert(wordLower + "ed")    // 过去式基本形式
        variations.insert(wordLower + "ing")   // 现在分词基本形式
        
        // 处理以 'e' 结尾的情况
        if wordLower.hasSuffix("e") {
            let stem = String(wordLower.dropLast())
            variations.insert(stem + "ed")    // 如 like -> liked
            variations.insert(stem + "ing")   // 如 like -> liking
        }
        
        // 处理需要双写辅音字母的情况
        let vowels = Set("aeiou")
        let lastThree = wordLower.suffix(3)
        if wordLower.count >= 3,
           !vowels.contains(lastThree[lastThree.startIndex]),
           vowels.contains(lastThree[lastThree.index(after: lastThree.startIndex)]),
           !vowels.contains(lastThree[lastThree.index(before: lastThree.endIndex)]) {
            variations.insert(wordLower + wordLower.suffix(1) + "ed")   // 如 stop -> stopped
            variations.insert(wordLower + wordLower.suffix(1) + "ing")  // 如 stop -> stopping
        }
        
        // 添加 -ly 形式
        // 对于基本形式
        variations.insert(wordLower + "ly")    // 如 quick -> quickly
        
        // 对于 -ing 形式
        // 1. 直接的 -ing 形式
        let ingForm = wordLower + "ing"
        variations.insert(ingForm)
        variations.insert(ingForm + "ly")  // 如 striking -> strikingly
        
        // 2. 去掉 e 后的 -ing 形式
        if wordLower.hasSuffix("e") {
            let stem = String(wordLower.dropLast())
            let ingForm = stem + "ing"
            variations.insert(ingForm)
            variations.insert(ingForm + "ly")  // 如 strike -> strikingly
        }
        
        
        // 3. 双写辅音字母的 -ing 形式
        if wordLower.count >= 3 {
            let doubleConsonantIng = wordLower + wordLower.suffix(1) + "ing"
            variations.insert(doubleConsonantIng)
            variations.insert(doubleConsonantIng + "ly")  // 如 stun -> stunningly
        }
        
        return variations
    }
          }
enum CodingKeys: String, CodingKey {
    case id, word, sentence, errorCount, createdAt, level, lastReviewDate, nextReviewDate, isFirstPractice, practiceHistory, actualWordForm
}
