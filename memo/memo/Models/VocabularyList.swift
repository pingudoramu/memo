//
//  VocabularyList.swift
//  memo
//
//  Created by mac on 2024/11/5.
//

import Foundation

// Define SortCriterion enum
enum SortCriterion: String, Codable, CaseIterable {
    case errorCount
    case alphabetical
    case date
    case random
    case level
}

struct VocabularyList: Identifiable, Codable {
    let id: UUID
    var name: String
    var entries: [WordEntry]
    let isDefault: Bool
    
    init(name: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.entries = []
        self.isDefault = isDefault
    }
    
    func sortedEntries(by criterion: SortCriterion, ascending: Bool = true, randomSeed: UUID = UUID()) -> [WordEntry] {
        switch criterion {
            case .errorCount:
                return entries.sorted { lhs, rhs in
                    ascending ? lhs.errorCount < rhs.errorCount : lhs.errorCount > rhs.errorCount
                }
            case .alphabetical:
                return entries.sorted { lhs, rhs in
                    let comparison = lhs.word.localizedStandardCompare(rhs.word)
                    return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
                }
            case .date:
                return entries.sorted { lhs, rhs in
                    ascending ? lhs.createdAt < rhs.createdAt : lhs.createdAt > rhs.createdAt
                }
            case .random:
                return entries.shuffled()
        case .level:
            return entries.sorted { lhs, rhs in
                ascending ? lhs.level < rhs.level : lhs.level > rhs.level
            }
        }
    }
}
