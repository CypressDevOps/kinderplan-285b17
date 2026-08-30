import SwiftUI

/// Sheet: Smarter Betreuungsplan-Import.
/// Akzeptiert Freitext, Tabellen (Woche A/B) oder Standard-Vorgaben und liefert eine strukturierte Bestätigungsansicht.
public struct PlanImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CareStore.self) private var store
    
    @State private var inputText: String = ""
    @State private var startDate: Date = Date()
    @State private var parseResult: NaturalPlanParser.ParseResult?
    @State private var isShowingConfirmation: Bool = false
    @State private var selectedTemplateIndex: Int = 0
    
    private let templateOptions = [
        ("Woche A/B (Beispiel)", "Woche A:\nMo & Di Janni\nMi & Do Lena\nFr & Sa Janni\nSo Lena\n\nWoche B:\nMo & Di Janni\nMi & Do Lena\nFr & Sa Janni\nSo Lena"),
        ("Wochenwechsel (7/7)", "7 Tage bei Janni, danach 7 Tage bei Lena. Wechsel jeden Freitag."),
        ("2/2/3 Wechsel", "Montag & Dienstag bei Janni\nMittwoch & Donnerstag bei Lena\nFreitag bis Sonntag bei Janni"),
        ("Eigener Text", "")
    ]
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spaceLG) {
                    
                    if !isShowingConfirmation {
                        // MARK: - Eingabebereich
                        VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                            Text("WIE SIEHT EUER PLAN AUS?")
                                .font(AppTheme.eyebrow)
                                .kerning(1.2)
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            Text("Gib euren Betreuungsplan einfach als Text, Tabelle oder in deinen eigenen Worten ein.")
                                .font(AppTheme.subheadline)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        
                        // Vorlagen-Auswahl
                        VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                            Text("SCHNELLE VORLAGEN")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.spaceXS) {
                                    ForEach(0..<templateOptions.count, id: \.self) { idx in
                                        Button {
                                            selectedTemplateIndex = idx
                                            if !templateOptions[idx].1.isEmpty {
                                                inputText = templateOptions[idx].1
                                            }
                                        } label: {
                                            Text(templateOptions[idx].0)
                                                .font(AppTheme.footnote)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(selectedTemplateIndex == idx ? AppTheme.accent : AppTheme.surface)
                                                .foregroundStyle(selectedTemplateIndex == idx ? Color.white : AppTheme.text)
                                                .clipShape(Capsule())
                                                .overlay(
                                                    Capsule().strokeBorder(AppTheme.border, lineWidth: selectedTemplateIndex == idx ? 0 : 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Startdatum
                        VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                            Text("AB WANN GILT DIESER PLAN?")
                                .font(AppTheme.eyebrow)
                                .kerning(1.2)
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            DatePicker(
                                "Startdatum",
                                selection: $startDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.compact)
                            .padding(AppTheme.spaceMD)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).strokeBorder(AppTheme.border, lineWidth: 1))
                        }
                        
                        // Großes Freitextfeld
                        VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                            Text("PLAN-BESCHREIBUNG")
                                .font(AppTheme.eyebrow)
                                .kerning(1.2)
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            TextEditor(text: $inputText)
                                .frame(minHeight: 180)
                                .padding(AppTheme.spaceSM)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                                        .strokeBorder(AppTheme.border, lineWidth: 1)
                                )
                        }
                        
                        // Button: Plan auswerten
                        Button {
                            parseInput()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "wand.and.stars")
                                Text("Plan auswerten & prüfen")
                            }
                        }
                        .buttonStyle(PrimaryCapsuleButtonStyle())
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        
                    } else if let result = parseResult {
                        
                        // MARK: - Bestätigungsansicht
                        PlanConfirmationCard(
                            result: result,
                            parents: store.parents,
                            startDate: startDate,
                            onAccept: {
                                store.applyNewPlan(
                                    name: "Aktualisierter Plan",
                                    startDate: startDate,
                                    recurrenceType: result.recurrenceType,
                                    cycleWeeks: result.cycleWeeks,
                                    days: result.detectedDays
                                )
                                dismiss()
                            },
                            onEditAgain: {
                                isShowingConfirmation = false
                            }
                        )
                    }
                }
                .padding(AppTheme.screenMargin)
            }
            .background(AppTheme.background)
            .navigationTitle("Betreuungsplan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Schließen") { dismiss() }
                }
            }
            .onAppear {
                if inputText.isEmpty {
                    inputText = templateOptions[0].1
                }
            }
        }
    }
    
    private func parseInput() {
        let result = NaturalPlanParser.parse(
            text: inputText,
            parents: store.parents,
            defaultStartDate: startDate
        )
        self.parseResult = result
        self.isShowingConfirmation = true
    }
}

// MARK: - Bestätigungskarte

struct PlanConfirmationCard: View {
    let result: NaturalPlanParser.ParseResult
    let parents: [Parent]
    let startDate: Date
    let onAccept: () -> Void
    let onEditAgain: () -> Void
    
    private var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter.string(from: startDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spaceLG) {
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ich habe euren Plan so verstanden:")
                        .font(AppTheme.title2)
                        .foregroundStyle(AppTheme.text)
                    Text("Automatische Erkennung (Demo)")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            
            // Meta-Informationen
            VStack(spacing: AppTheme.spaceSM) {
                HStack {
                    Text("Startdatum")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text(formattedStartDate)
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.text)
                }
                Divider()
                HStack {
                    Text("Wiederholung")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Text(result.recurrenceType.label)
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.text)
                }
            }
            .padding(AppTheme.spaceMD)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).strokeBorder(AppTheme.border, lineWidth: 1))
            
            // Tageszuordnung je Woche
            VStack(alignment: .leading, spacing: AppTheme.spaceMD) {
                Text("ERKANNTE TAGE")
                    .font(AppTheme.eyebrow)
                    .kerning(1.2)
                    .foregroundStyle(AppTheme.textSecondary)
                
                ForEach(0..<result.cycleWeeks, id: \.self) { weekIdx in
                    VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                        Text(result.cycleWeeks > 1 ? (weekIdx == 0 ? "Woche A" : "Woche B") : "Woche")
                            .font(AppTheme.headline)
                            .foregroundStyle(AppTheme.accent)
                        
                        let weekDays = result.detectedDays.filter { $0.weekIndex == weekIdx }.sorted { $0.dayIndex < $1.dayIndex }
                        ForEach(weekDays) { day in
                            let parentName = parents.first(where: { $0.id == day.parentId })?.displayName ?? "Elternteil"
                            let parentInitial = parents.first(where: { $0.id == day.parentId })?.initial ?? "E"
                            let parentColor = parents.first(where: { $0.id == day.parentId })?.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor
                            
                            HStack {
                                Text(weekdayName(for: day.dayIndex))
                                    .font(AppTheme.subheadline)
                                    .foregroundStyle(AppTheme.text)
                                    .frame(width: 100, alignment: .leading)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.textSecondary)
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(parentColor)
                                        .frame(width: 20, height: 20)
                                        .overlay(
                                            Text(parentInitial)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundStyle(Color.white)
                                        )
                                    Text(parentName)
                                        .font(AppTheme.headline)
                                        .foregroundStyle(AppTheme.text)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(AppTheme.spaceMD)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).strokeBorder(AppTheme.border, lineWidth: 1))
                }
            }
            
            // Buttons
            VStack(spacing: AppTheme.spaceSM) {
                Button(action: onAccept) {
                    Text("Plan übernehmen & aktivieren")
                }
                .buttonStyle(PrimaryCapsuleButtonStyle())
                
                Button(action: onEditAgain) {
                    Text("Text nochmals bearbeiten")
                }
                .buttonStyle(SecondaryCapsuleButtonStyle())
            }
            .padding(.top, AppTheme.spaceSM)
        }
    }
    
    private func weekdayName(for index: Int) -> String {
        let names = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
        guard index >= 0 && index < names.count else { return "Tag" }
        return names[index]
    }
}
