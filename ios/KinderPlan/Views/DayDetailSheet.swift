import SwiftUI

/// Sheet: Zeigt die vollständige Tageskarte für ein gewähltes Datum.
/// Ermöglicht das Ändern der Betreuung (einmalige Ausnahme vs. dauerhaftes Muster),
/// Übergabe-Informationen, Notizen und Verknüpfung zum Familien-Chat.
public struct DayDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CareStore.self) private var store
    
    let date: Date
    
    @State private var showingChangeModeSheet = false
    @State private var showingAddNoteSheet = false
    @State private var newNoteText = ""
    @State private var selectedCategory = "Übergabe"
    
    private var dayInfo: DayCareInfo {
        store.infoForDay(date: date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private var parentColor: Color {
        dayInfo.parent.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spaceLG) {
                    
                    // MARK: - Hero: Betreuender Elternteil
                    VStack(spacing: AppTheme.spaceSM) {
                        HStack {
                            Circle()
                                .fill(parentColor)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text(dayInfo.parent.initial)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(Color.white)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Betreuung")
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Text(dayInfo.parent.displayName)
                                    .font(AppTheme.title1)
                                    .foregroundStyle(AppTheme.text)
                            }
                            Spacer()
                        }
                        
                        if dayInfo.isException {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(AppTheme.exceptionAccent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ausnahme / Abweichung vom Plan")
                                        .font(AppTheme.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.exceptionAccent)
                                    if let reason = dayInfo.exceptionReason {
                                        Text(reason)
                                            .font(AppTheme.footnote)
                                            .foregroundStyle(AppTheme.text)
                                    }
                                }
                                Spacer()
                                Button("Zurücksetzen") {
                                    store.removeException(for: date)
                                }
                                .font(AppTheme.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppTheme.exceptionAccent)
                            }
                            .padding(AppTheme.spaceMD)
                            .background(AppTheme.exceptionBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                                Text("Entspricht dem regulären Betreuungsplan")
                                    .font(AppTheme.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                            }
                            .padding(AppTheme.spaceMD)
                            .background(AppTheme.surfaceSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                        }
                    }
                    .padding(AppTheme.spaceMD)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                            .strokeBorder(AppTheme.border, lineWidth: 1)
                    )
                    
                    // MARK: - Übergabe & Details
                    VStack(alignment: .leading, spacing: AppTheme.spaceSM) {
                        Text("ÜBERGABE")
                            .font(AppTheme.eyebrow)
                            .kerning(1.2)
                            .foregroundStyle(AppTheme.textSecondary)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(AppTheme.accent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(store.transitionRules.first?.location ?? "Kita")
                                        .font(AppTheme.headline)
                                        .foregroundStyle(AppTheme.text)
                                    Text(store.transitionRules.first?.defaultNote ?? "Nach der Kita · 16:00 Uhr")
                                        .font(AppTheme.footnote)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(AppTheme.spaceMD)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                                .strokeBorder(AppTheme.border, lineWidth: 1)
                        )
                    }
                    
                    // MARK: - Notizen zu diesem Tag
                    VStack(alignment: .leading, spacing: AppTheme.spaceSM) {
                        HStack {
                            Text("NOTIZEN")
                                .font(AppTheme.eyebrow)
                                .kerning(1.2)
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Button("+ Notiz") {
                                showingAddNoteSheet = true
                            }
                            .font(AppTheme.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.accent)
                        }
                        
                        if dayInfo.notes.isEmpty {
                            HStack {
                                Text("Keine Notizen für diesen Tag.")
                                    .font(AppTheme.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                                Spacer()
                            }
                            .padding(AppTheme.spaceMD)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).strokeBorder(AppTheme.border, lineWidth: 1))
                        } else {
                            VStack(spacing: AppTheme.spaceXS) {
                                ForEach(dayInfo.notes) { note in
                                    HStack(alignment: .top, spacing: AppTheme.spaceSM) {
                                        Image(systemName: "note.text")
                                            .font(.system(size: 16))
                                            .foregroundStyle(AppTheme.accent)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(note.category)
                                                .font(AppTheme.eyebrow)
                                                .foregroundStyle(AppTheme.textSecondary)
                                            Text(note.text)
                                                .font(AppTheme.body)
                                                .foregroundStyle(AppTheme.text)
                                        }
                                        Spacer()
                                    }
                                    .padding(AppTheme.spaceMD)
                                    .background(AppTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).strokeBorder(AppTheme.border, lineWidth: 1))
                                }
                            }
                        }
                    }
                    
                    // MARK: - Primäre Aktionen
                    VStack(spacing: AppTheme.spaceSM) {
                        Button {
                            showingChangeModeSheet = true
                        } label: {
                            Text("Betreuung ändern / Ausnahme erstellen")
                        }
                        .buttonStyle(PrimaryCapsuleButtonStyle())
                        
                        Button {
                            store.sendChatMessage(
                                text: "Frage zu Betreuung am \(formattedDate): Können wir abstimmen?",
                                linkedDate: date
                            )
                            dismiss()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                Text("Im Chat besprechen")
                            }
                        }
                        .buttonStyle(SecondaryCapsuleButtonStyle())
                    }
                    .padding(.top, AppTheme.spaceSM)
                }
                .padding(AppTheme.screenMargin)
            }
            .background(AppTheme.background)
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accent)
                }
            }
            .sheet(isPresented: $showingChangeModeSheet) {
                ChangeDayCareSheet(date: date, currentInfo: dayInfo)
            }
            .sheet(isPresented: $showingAddNoteSheet) {
                AddNoteSheet(date: date)
            }
        }
    }
}

// MARK: - Sub-Sheet für Betreuungsänderung

struct ChangeDayCareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CareStore.self) private var store
    
    let date: Date
    let currentInfo: DayCareInfo
    
    @State private var selectedParentId: UUID
    @State private var changeScope: ChangeScope = .onlyThisDay
    @State private var reason: String = "Wochenendtausch"
    @State private var customNote: String = ""
    
    enum ChangeScope: String, CaseIterable {
        case onlyThisDay = "Nur diesen Tag ändern"
        case permanent = "Ab diesem Tag dauerhaft"
    }
    
    init(date: Date, currentInfo: DayCareInfo) {
        self.date = date
        self.currentInfo = currentInfo
        // Standardmäßig den anderen Elternteil wählen
        let other = currentInfo.parent.id == currentInfo.parent.id ? currentInfo.parent.id : currentInfo.parent.id
        _selectedParentId = State(initialValue: other)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Zuständiger Elternteil")) {
                    Picker("Elternteil", selection: $selectedParentId) {
                        ForEach(store.parents) { parent in
                            Text(parent.displayName).tag(parent.id)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Umfang der Änderung"), footer: Text("Die App unterscheidet strikt zwischen einer einmaligen Ausnahme und einer dauerhaften Planänderung.")) {
                    Picker("Umfang", selection: $changeScope) {
                        ForEach(ChangeScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Grund & Notiz (optional)")) {
                    TextField("Grund (z.B. Urlaub, Termintausch)", text: $reason)
                    TextField("Notiz zur Übergabe", text: $customNote)
                }
            }
            .navigationTitle("Betreuung anpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        saveChange()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
    
    private func saveChange() {
        if changeScope == .onlyThisDay {
            store.setDayException(
                date: date,
                parentId: selectedParentId,
                reason: reason.isEmpty ? "Ausnahme" : reason,
                note: customNote.isEmpty ? nil : customNote
            )
        } else {
            // Dauerhafte Planänderung ab diesem Tag: wir aktualisieren den Startplan
            if let active = store.activePlan {
                store.applyNewPlan(
                    name: "Angepasster Plan",
                    startDate: date,
                    recurrenceType: active.recurrenceType,
                    cycleWeeks: active.cycleWeeks,
                    days: active.days
                )
            }
        }
        dismiss()
    }
}

// MARK: - Sub-Sheet für Notizen

struct AddNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CareStore.self) private var store
    
    let date: Date?
    @State private var text = ""
    @State private var category = "Übergabe"
    
    let categories = ["Übergabe", "Kita / Schule", "Gesundheit", "Ausrüstung", "Allgemein"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Kategorie")) {
                    Picker("Kategorie", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("Notiztext")) {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Notiz hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Speichern") {
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            store.addNote(text: text, date: date, category: category)
                        }
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accent)
                }
            }
        }
    }
}
