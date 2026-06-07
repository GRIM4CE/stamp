import SwiftUI

/// Language and export-destination preferences, shown as a sheet from the header.
struct SettingsView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let t = state.strings
        VStack(alignment: .leading, spacing: 20) {
            Text(t.settingsTitle)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.inkNavy)

            VStack(alignment: .leading, spacing: 8) {
                Text(t.languageLabel).font(.headline).foregroundStyle(Theme.inkNavy)
                Picker("", selection: languageBinding) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(t.exportFolderLabel).font(.headline).foregroundStyle(Theme.inkNavy)
                Picker("", selection: sourceFolderBinding) {
                    Text(t.sameAsOriginals).tag(true)
                    Text(t.customFolder).tag(false)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()

                if !state.useSourceFolder {
                    HStack(spacing: 8) {
                        Text(state.outputFolder.path)
                            .font(.caption)
                            .foregroundStyle(Theme.inkNavy.opacity(0.7))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(t.chooseFolder) { chooseFolder() }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.leading, 20)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button(t.done) { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420, height: 320)
        .background(Theme.aliceBlue)
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(get: { state.language }, set: { state.setLanguage($0) })
    }

    private var sourceFolderBinding: Binding<Bool> {
        Binding(get: { state.useSourceFolder }, set: { state.setUseSourceFolder($0) })
    }

    private func chooseFolder() {
        if let url = ImportService.pickFolder(startingAt: state.outputFolder, strings: state.strings) {
            state.setOutputFolder(url)
        }
    }
}
