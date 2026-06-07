import Foundation

/// The two languages the UI can switch between at runtime.
enum AppLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .french: return "Français"
        case .english: return "English"
        }
    }
}

/// All user-facing strings for the selected language. Held by `AppState` and read
/// by the views, so flipping the language re-renders the whole UI in place.
struct L10n {
    let lang: AppLanguage

    private func pick(_ fr: String, _ en: String) -> String {
        lang == .french ? fr : en
    }

    // Header / sidebar
    var sidebarShow: String { pick("Afficher la liste", "Show list") }
    var sidebarHide: String { pick("Masquer la liste", "Hide list") }
    var addDocument: String { pick("Ajouter des documents", "Add documents") }
    var selectInvoice: String {
        pick("Sélectionnez une facture pour prévisualiser le tampon",
             "Select an invoice to preview the stamp")
    }

    // Document list
    var noInvoices: String { pick("Aucune facture pour l'instant", "No invoices yet") }
    var dragHint: String {
        pick("Glissez des fichiers ici, ou utilisez le bouton ci-dessus.",
             "Drag files here, or use the button above.")
    }
    var allSaved: String { pick("Tout est enregistré", "All saved") }
    var remove: String { pick("Retirer", "Remove") }
    func saveAll(_ count: Int) -> String { pick("Tout enregistrer (\(count))", "Save all (\(count))") }
    func saving(_ done: Int, _ total: Int) -> String {
        pick("Enregistrement \(done)/\(total)…", "Saving \(done)/\(total)…")
    }

    // Status
    var statusReady: String { pick("Prêt", "Ready") }
    var statusSaved: String { pick("Enregistré", "Saved") }
    var statusFailed: String { pick("Échec", "Failed") }

    // Preview
    func pageCount(_ n: Int) -> String { pick("\(n) page\(n > 1 ? "s" : "")", "\(n) page\(n == 1 ? "" : "s")") }
    var dragStamp: String { pick("Cliquez-glissez le tampon, ou utilisez les boutons, pour l'ajuster", "Click and drag the stamp, or use the buttons, to adjust it") }
    var approveSave: String { pick("Valider et enregistrer", "Approve and save") }
    var adjust: String { pick("Ajuster", "Adjust") }
    var deduction: String { pick("Déduction", "Deduction") }

    // Settings
    var settingsTitle: String { pick("Réglages", "Settings") }
    var languageLabel: String { pick("Langue", "Language") }
    var exportFolderLabel: String { pick("Dossier d'export", "Export folder") }
    var sameAsOriginals: String { pick("Même dossier que les originaux", "Same folder as originals") }
    var customFolder: String { pick("Dossier personnalisé", "Custom folder") }
    var chooseFolder: String { pick("Choisir un dossier…", "Choose a folder…") }
    var done: String { pick("Terminé", "Done") }

    // File panels
    var pickFilesMessage: String {
        pick("Choisissez les factures PDF à tamponner", "Choose the PDF invoices to stamp")
    }
    var pickFilesPrompt: String { pick("Ajouter", "Add") }
    var pickFolderMessage: String {
        pick("Choisissez où enregistrer les PDF tamponnés", "Choose where to save the stamped PDFs")
    }
    var pickFolderPrompt: String { pick("Choisir", "Choose") }
}
