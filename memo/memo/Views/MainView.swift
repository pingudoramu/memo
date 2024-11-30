//
//  MainView.swift
//  memo
//
//  Created by mac on 2024/11/5.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = WordListViewModel()
    @State private var showingAddWord = false
    @State private var showingAddList = false
    @State private var selectedListId: UUID?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                // Forgetting Curve Card
                NavigationLink(destination: ForgettingCurveView(viewModel: viewModel)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Forgetting\nCurve")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.leading)
                            Text("Today")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Text("\(viewModel.getTodayReviewCount())")
                            .font(.system(.title, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.top, -10)
                    }
                    .padding()
                    .background(Color.themeColor)
                    .cornerRadius(10)
                    .frame(width: UIScreen.main.bounds.width * 0.45)
                }
                .padding(.horizontal)
                .padding(.top, 50)
                    
                    // List Items
                    Form {
                        Section(header:
                            Text("Lists")
                                .font(.system(.title, design: .rounded))
                                .foregroundColor(.gray)
                                .textCase(nil)
                                .padding(.vertical, 20)
                        ) {
                            if viewModel.wordLists.isEmpty {
                                Text("No Lists")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .listRowBackground(Color.clear)
                            } else {
                                ForEach(viewModel.wordLists) { list in
                                    VStack(spacing: 0) {
                                        HStack {
                                            Text(list.name)
                                                .font(.system(.body, design: .rounded))
                                                .foregroundColor(Color(uiColor: .darkGray))
                                            Spacer()
                                            Text("\(list.entries.count)")
                                                .font(.system(.subheadline, design: .rounded))  // 改成subheadline
                                                .foregroundColor(.secondary)  // 改成secondary
                                            Image(systemName: "chevron.forward")
                                                .foregroundColor(.gray)
                                                .font(.subheadline.bold())
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 6)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedListId = list.id
                                        }
                                    }
                                    // 每个列表项的背景色
                                    .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if !list.isDefault {
                                            Button(role: .destructive) {
                                                deleteList(list)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)  // 保持这一行
                    .background(Color(uiColor: .systemGroupedBackground))// 整个Form 的背景色？
                    .background(
                        NavigationLink(destination: Group {
                            if let listId = selectedListId {
                                ListView(viewModel: viewModel, listId: listId)
                            }
                        }, isActive: Binding(
                            get: { selectedListId != nil },
                            set: { if !$0 { selectedListId = nil } }
                        )) { EmptyView() }
                    )
                    
                    Spacer()
                
                // Bottom Buttons
                HStack {
                    if !viewModel.wordLists.isEmpty {
                        Button(action: {
                            showingAddWord = true
                        }) {
                            Label("Add Words", systemImage: "plus.circle.fill")
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(.themeColor)
                        }
                        .sheet(isPresented: $showingAddWord) {
                            AddWordView(viewModel: viewModel)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Add List") {
                        showingAddList = true
                    }
                    .sheet(isPresented: $showingAddList) {
                        AddListView(viewModel: viewModel)
                    }
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.themeColor)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("MEMO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Setting") {
                        SettingsView(viewModel: viewModel)
                    }
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.themeColor)
                }
            }
        }
    }
    
    private func deleteList(_ list: VocabularyList) {
        viewModel.wordLists.removeAll(where: { $0.id == list.id })
    }
}
