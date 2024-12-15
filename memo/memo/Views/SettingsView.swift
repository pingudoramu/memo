//
//  SettingsView.swift
//  memo
//
//  Created by mac on 2024/11/5.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("wordsPerGroup") private var wordsPerGroup: Int = 3
    @AppStorage("readAloudEnabled") private var readAloudEnabled: Bool = false
    @ObservedObject var viewModel: WordListViewModel
    @State private var showingDocumentPicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    
    private let wordsPerGroupOptions = [3, 6, 9]
    
    var body: some View {
        Form {
            Section {
                // Words per group setting
                Picker("Words per Group", selection: $wordsPerGroup) {
                    ForEach(wordsPerGroupOptions, id: \.self) { number in
                        Text("\(number)")
                            .font(.system(.body, design: .rounded))
                            .tag(number)
                    }
                }
                .font(.system(.body, design: .rounded))
                
                // Read aloud toggle
                Toggle("Read Aloud", isOn: $readAloudEnabled)
                    .font(.system(.body, design: .rounded))
            }
            
            Section {
                Button(action: {
                    let exportedData = viewModel.exportLists()
                    shareFiles(exportedData)
                }) {
                    HStack {
                        Text("Export All Lists")
                            .font(.system(.body, design: .rounded))
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundColor(.themeColor)
                }
                
                Button(action: {
                    showingDocumentPicker = true
                }) {
                    HStack {
                        Text("Import Lists")
                            .font(.system(.body, design: .rounded))
                        Spacer()
                        Image(systemName: "square.and.arrow.down")
                    }
                    .foregroundColor(.themeColor)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPicker(viewModel: viewModel,
                         showingError: $showingError,
                         errorMessage: $errorMessage,
                         showingSuccess: $showingSuccess,
                         successMessage: $successMessage)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(successMessage)
        }
    }
    
    private func shareFiles(_ files: [(fileName: String, csvData: String)]) {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let exportedFiles = files.compactMap { fileName, csvData -> URL? in
            let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
            do {
                try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
                return fileURL
            } catch {
                print("Error writing file: \(error)")
                return nil
            }
        }
        
        let activityVC = UIActivityViewController(activityItems: exportedFiles, applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let viewModel: WordListViewModel
    @Binding var showingError: Bool
    @Binding var errorMessage: String
    @Binding var showingSuccess: Bool
    @Binding var successMessage: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            var importedCount = 0
            
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else {
                    parent.errorMessage = "Permission denied to access the file"
                    parent.showingError = true
                    return
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                do {
                    let data = try String(contentsOf: url)
                    let listName = url.deletingPathExtension().lastPathComponent
                    
                    if let entries = parseCSV(data) {
                        parent.viewModel.createList(name: listName)
                        
                        if let listId = parent.viewModel.wordLists.last?.id {
                            for entry in entries {
                                parent.viewModel.addWordEntry(entry, to: listId)
                            }
                            importedCount += 1
                        }
                    }
                } catch {
                    parent.errorMessage = "Error reading file: \(error.localizedDescription)"
                    parent.showingError = true
                    return
                }
            }
            
            if importedCount > 0 {
                parent.successMessage = "Successfully imported \(importedCount) list\(importedCount > 1 ? "s" : "")"
                parent.showingSuccess = true
            }
        }
        
        private func parseCSV(_ data: String) -> [WordEntry]? {
            let lines = data.components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            
            guard lines.count > 1 else {
                parent.errorMessage = "File is empty or invalid"
                parent.showingError = true
                return nil
            }
            
            let headers = lines[0].components(separatedBy: ";")
            guard headers.contains("Word") && headers.contains("Sentence") else {
                parent.errorMessage = "Required columns 'Word' and 'Sentence' not found"
                parent.showingError = true
                return nil
            }
            
            var entries: [WordEntry] = []
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            let calendar = Calendar.current
            
            for line in lines.dropFirst() {
                var fields: [String] = []
                var currentField = ""
                var insideQuotes = false
                
                for char in line {
                    switch char {
                    case "\"":
                        insideQuotes.toggle()
                    case ";":
                        if !insideQuotes {
                            fields.append(currentField)
                            currentField = ""
                        } else {
                            currentField.append(char)
                        }
                    default:
                        currentField.append(char)
                    }
                }
                fields.append(currentField)
                
                guard fields.count >= 5 else { continue }
                
                let word = fields[0].trimmingCharacters(in: .whitespaces)
                var sentence = fields[1].trimmingCharacters(in: .whitespaces)
                
                if sentence.hasPrefix("\"") && sentence.hasSuffix("\"") {
                    sentence = String(sentence.dropFirst().dropLast())
                    sentence = sentence.replacingOccurrences(of: "\"\"", with: "\"")
                }
                
                guard WordEntry.validate(word: word, sentence: sentence) else {
                    continue
                }
                
                let level = Int(fields[2]) ?? 1
                let createdDate = dateFormatter.date(from: fields[3]) ?? Date()
                let nextReviewDate = dateFormatter.date(from: fields[4]).map { date in
                    calendar.startOfDay(for: date)
                } ?? calendar.startOfDay(for: Date())
                
                let entry = WordEntry(
                    importing: word,
                    sentence: sentence,
                    level: level,
                    createdAt: createdDate,
                    nextReviewDate: nextReviewDate
                )
                
                entries.append(entry)
            }
            
            return entries.isEmpty ? nil : entries
        }
           }
       }

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(viewModel: WordListViewModel())
        }
    }
       }

