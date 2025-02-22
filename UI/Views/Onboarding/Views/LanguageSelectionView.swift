import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var languageManager = LanguageManager.shared
    @State private var selectedLanguage: LanguageManager.Language
    @State private var showRestartAlert = false
    
    init() {
        _selectedLanguage = State(initialValue: LanguageManager.shared.currentLanguage)
    }
    
    var body: some View {
        NavigationView {
            List(LanguageManager.Language.allCases) { language in
                Button(action: {
                    selectedLanguage = language
                    showRestartAlert = true
                }) {
                    HStack {
                        Text(language.flag)
                            .font(.title2)
                        Text(language.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        if language == selectedLanguage {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("select_language", comment: ""))
            .navigationBarItems(trailing: Button(NSLocalizedString("cancel", comment: "")) {
                dismiss()
            })
        }
        .alert(NSLocalizedString("language_change_title", comment: ""), isPresented: $showRestartAlert) {
            Button(NSLocalizedString("restart_now", comment: ""), role: .destructive) {
                languageManager.setLanguage(selectedLanguage)
                // Trigger app restart
                exit(0)
            }
            Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {
                selectedLanguage = languageManager.currentLanguage
            }
        } message: {
            Text(NSLocalizedString("language_change_message", comment: ""))
        }
    }
} 