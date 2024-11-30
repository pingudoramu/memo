//
//  AddWordView.swift
//  memo
//
//  Created by mac on 2024/11/5.
//

import SwiftUI

struct AddWordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WordListViewModel
    @State private var input = ""
    @State private var selectedListId: UUID?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(viewModel: WordListViewModel) {
        self.viewModel = viewModel
        
        // 获取最后使用的列表ID
        if let lastUsedId = viewModel.getLastUsedListId() {
            _selectedListId = State(initialValue: lastUsedId)
        } else {
            // 如果没有最后使用的列表，使用第一个可用的列表
            _selectedListId = State(initialValue: viewModel.wordLists.first?.id)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                // List selection
                Picker("Select List", selection: $selectedListId) {
                    ForEach(viewModel.wordLists) { list in
                        Text(list.name)
                            .font(.system(.body, design: .rounded))
                            .tag(Optional(list.id))
                    }
                }
                .font(.system(.body, design: .rounded))
                
                    

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $input)
                            .frame(minHeight: 150)
                            .textInputAutocapitalization(.never)
                            .font(.system(.body, design: .rounded))
                        
                        if input.isEmpty {
                            Text("eg: word;sentence containing the word")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.top, 7)    // 调整这个值来匹配 TextEditor 的内部 padding
                                .padding(.leading, 5) // 调整这个值来匹配 TextEditor 的内部 padding
                                .allowsHitTesting(false) // 确保点击事件传递到 TextEditor
                        }
                    }

                }
                
 

                
                
            }
            .navigationTitle("Add Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addWords()
                    }
                    .font(.system(.body, design: .rounded))
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
                    .font(.system(.body, design: .rounded))
            } message: {
                Text(errorMessage)
                    .font(.system(.body, design: .rounded))
            }
        }
    }
    
    private func addWords() {
        guard let listId = selectedListId else {
            errorMessage = "Please select a list"
            showingError = true
            return
        }
        
        // Split input into lines and process each line
        let lines = input.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        var hasError = false
        var addedCount = 0
        
        for line in lines {
            let components = line.split(separator: ";").map(String.init)
            if components.count != 2 {
                hasError = true
                continue
            }
            
            let word = components[0].trimmingCharacters(in: .whitespaces)
            let sentence = components[1].trimmingCharacters(in: .whitespaces)
            
            if WordEntry.validate(word: word, sentence: sentence) {
                let entry = WordEntry(word: word, sentence: sentence)
                viewModel.addWordEntry(entry, to: listId)
                addedCount += 1
            } else {
                hasError = true
            }
        }
        
        if hasError {
            errorMessage = addedCount > 0
                ? "Some entries were invalid and skipped. Added \(addedCount) words successfully."
                : "No valid entries found. Please check the format."
            showingError = true
        } else if addedCount > 0 {
            dismiss()
        } else {
            errorMessage = "Please enter at least one word and sentence"
            showingError = true
        }
    }
}
