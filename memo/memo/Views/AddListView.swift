import SwiftUI

struct AddListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WordListViewModel
    @State private var listName = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("List Name", text: $listName)
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createList(name: listName)
                        dismiss()
                    }
                    .disabled(listName.isEmpty)
                }
            }
        }
    }
}
