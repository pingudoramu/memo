//
//  ListView.swift
//  memo
//
//  Created by mac on 2024/11/5.
//

import SwiftUI

enum SortOption: String, Codable, Equatable {
    case aToZ
    case zToA
    case earliestDate
    case latestDate
    case random
    case urgentReview
    case nonUrgentReview
    
    var description: String {
        switch self {
        case .aToZ:
            return "A to Z"
        case .zToA:
            return "Z to A"
        case .earliestDate:
            return "Earliest Date"
        case .latestDate:
            return "Latest Date"
        case .random:
            return "Random"
        case .urgentReview:
            return "Urgent Review"
        case .nonUrgentReview:
            return "Non-urgent Review"
        }
    }
    
    var criterion: SortCriterion {
        switch self {
        case .aToZ, .zToA:
            return .alphabetical
        case .earliestDate, .latestDate:
            return .date
        case .random:
            return .random
        case .urgentReview, .nonUrgentReview:
            return .date
        }
    }
    
    var isAscending: Bool {
        switch self {
        case .aToZ, .earliestDate:
            return true
        case .zToA, .latestDate:
            return false
        case .random:
            return true
        case .urgentReview:
            return true
        case .nonUrgentReview:
            return false
        }
    }
}

struct ListView: View {
    @ObservedObject var viewModel: WordListViewModel
    let listId: UUID
    @State private var sortOption: SortOption
    @State private var randomSeed = UUID()
    @AppStorage("readAloudEnabled") private var readAloudEnabled: Bool = false
    
    init(viewModel: WordListViewModel, listId: UUID) {
        self.viewModel = viewModel
        self.listId = listId
        
        let savedSortOption = UserDefaults.standard.string(forKey: "sortOption_\(listId.uuidString)")
        let initialSortOption: SortOption
        
        if let savedOption = savedSortOption,
           let decodedOption = try? JSONDecoder().decode(SortOption.self, from: Data(savedOption.utf8)) {
            initialSortOption = decodedOption
        } else {
            initialSortOption = .latestDate
        }
        
        _sortOption = State(initialValue: initialSortOption)
    }
    
    private var list: VocabularyList? {
        viewModel.wordLists.first(where: { $0.id == listId })
    }
    
    private var currentSortText: String {
        sortOption.description
    }
    
    private func deleteEntry(_ entry: WordEntry) {
        viewModel.deleteEntry(entry.id, from: listId)
    }
    
    private func saveSortOption() {
        if let encoded = try? JSONEncoder().encode(sortOption),
           let string = String(data: encoded, encoding: .utf8) {
            UserDefaults.standard.set(string, forKey: "sortOption_\(listId.uuidString)")
        }
    }
    
    var body: some View {
            VStack {
                if let currentList = list {
                    // 1. 提取排序后的条目
                    let sortedEntries = currentList.sortedEntries(
                        by: sortOption.criterion,
                        ascending: sortOption.isAscending,
                        randomSeed: randomSeed
                    )
                    
                    // 2. 创建列表内容
                    ListContent(
                        entries: sortedEntries,
                        sortOption: sortOption,
                        readAloudEnabled: readAloudEnabled,
                        onDelete: deleteEntry
                    )
                    
                    // 3. Practice button
                    if !currentList.entries.isEmpty {
                        PracticeButton(viewModel: viewModel, listId: listId, sortOption: sortOption)
                    }
                }
            }
            .navigationTitle(list?.name ?? "List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SortMenu(sortOption: $sortOption)
                }
            }
            .onChange(of: sortOption) { _ in
                saveSortOption()
            }
        }
    }

// 提取列表内容为单独的视图
private struct ListContent: View {
    let entries: [WordEntry]
    let sortOption: SortOption
    let readAloudEnabled: Bool
    let onDelete: (WordEntry) -> Void
    
    var body: some View {
        List {
            Section {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 4) {
                            if (sortOption == .urgentReview || sortOption == .nonUrgentReview) {
                                Text("Lv.\(entry.level)/6")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundColor(.themeColor)
                            }
                            
                            Text(entry.displaySentence)
                                .font(.system(.body, design: .rounded))
                                .textSelection(.enabled) 
                                .onTapGesture {
                                    if readAloudEnabled {
                                        SpeechService.shared.speak(entry.sentence)
                                    }
                                }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDelete(entry)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .listSectionSeparator(.hidden, edges: .all)
        }
        .listStyle(.plain)
        .overlay {
            if entries.isEmpty {
                Text("No Words")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }
}


    // 提取练习按钮为单独的视图
    private struct PracticeButton: View {
        let viewModel: WordListViewModel
        let listId: UUID
        let sortOption: SortOption
        
        var body: some View {
            NavigationLink(destination: PracticeView(viewModel: viewModel, listId: listId, sortOption: sortOption)) {
                Text("Practice")
                    .font(.system(.headline, design: .rounded)).bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themeColor)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 15)
            .padding(.bottom, 10)
        }
    }

// 提取排序菜单为单独的视图
private struct SortMenu: View {
    @Binding var sortOption: SortOption
    
        var body: some View {
            Menu {
                Picker("Sort by", selection: $sortOption) {
                    // 字母顺序
                    Group {
                        Text("A to Z").tag(SortOption.aToZ)
                        Text("Z to A").tag(SortOption.zToA)
                    }
                    
                    // 日期相关
                    Group {
                        Text("Earliest Date").tag(SortOption.earliestDate)
                        Text("Latest Date").tag(SortOption.latestDate)
                    }
                    
                    // 其他选项
                    Group {
                        Text("Random").tag(SortOption.random)
                        Text("Urgent Review").tag(SortOption.urgentReview)
                        Text("Non-urgent Review").tag(SortOption.nonUrgentReview)
                    }
                }
            } label: {
                Text(sortOption.description)
                    .foregroundColor(.themeColor)
        }
    }
}

