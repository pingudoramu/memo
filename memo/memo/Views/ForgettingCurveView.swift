import SwiftUI

public struct ForgettingCurveView: View {
    @ObservedObject var viewModel: WordListViewModel
    @AppStorage("readAloudEnabled") private var readAloudEnabled: Bool = false
    @State private var sortOption: SortOption = .urgentReview
    
    private var entries: [WordEntry] {
        let allEntries = viewModel.getReviewEntries()
        switch sortOption {
        case .urgentReview:
            // 按照复习时间排序，最紧急的在前面
            return allEntries.sorted { $0.nextReviewDate < $1.nextReviewDate }
        case .nonUrgentReview:
            // 按照复习时间排序，最不紧急的在前面
            return allEntries.sorted { $0.nextReviewDate > $1.nextReviewDate }
        default:
            return allEntries
        }
    }
    
    public var body: some View {
        VStack {
            if entries.isEmpty {
                Text("No Words Need Review")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            } else {
                List {
                    Section {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 20) {
                                HStack(spacing: 4) {
                                    Text("Lv.\(entry.level)/6")
                                        .font(.system(.caption2, design: .rounded))
                                        .foregroundColor(.themeColor)
                                    
                                    Text(entry.displaySentence)
                                        .font(.system(.body, design: .rounded))
                                        .onTapGesture {
                                            if readAloudEnabled {
                                                SpeechService.shared.speak(entry.sentence)
                                            }
                                        }
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 15, leading: 20, bottom: 15, trailing: 20))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if let listId = viewModel.getListId(for: entry.id) {
                                    Button(role: .destructive) {
                                        viewModel.deleteEntry(entry.id, from: listId)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listSectionSeparator(.hidden, edges: .all)
                }
                .listStyle(.plain)
                
                // Practice button
                if !entries.isEmpty {
                    let practiceEntries = entries.map { (entry: WordEntry) -> WordEntry in  // 添加明确的类型
                        var copy = entry
                        copy.id = entry.id
                        copy.nextReviewDate = entry.nextReviewDate
                        copy.level = entry.level
                        copy.errorCount = entry.errorCount
                        return copy
                    }
                    
                    NavigationLink(destination: PracticeView(viewModel: viewModel, sortOption: .urgentReview, entries: practiceEntries)) {
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
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort by", selection: $sortOption) {
                        Text("Urgent Review").tag(SortOption.urgentReview)
                        Text("Non-urgent Review").tag(SortOption.nonUrgentReview)
                    }
                } label: {
                    Text(sortOption == .urgentReview ? "Urgent Review" : "Non-urgent Review")
                        .foregroundColor(.themeColor)
                }
            }
        }
    }
}
