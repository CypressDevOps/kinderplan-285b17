import SwiftUI

/// Tab 3 & Sheet: 'Bei wem?' – Schnelle Beantwortung von Zukunftsfragen
/// (z.B. 'Wer hat die Kinder am 14.11.?') und strukturierter Wochenend-Finder mit Filtersystem und Kalendersprung.
public struct WhoHasTheKidsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CareStore.self) private var store
    
    public enum SearchMode: String, CaseIterable {
        case quickQuery = "Frage stellen"
        case weekendFinder = "Wochenenden"
    }
    
    @State private var mode: SearchMode = .quickQuery
    
    // Quick Query State
    @State private var queryText: String = ""
    @State private var specificTargetDate: Date = Date()
    @State private var queryResultAnswer: String? = nil
    
    // Weekend Finder State
    @State private var selectedParentFilter: UUID? = nil // nil = beide
    @State private var timeHorizonMonths: Int = 6
    @State private var selectedDateForDaySheet: Date?
    
    private let horizonOptions = [
        ("3 Monate", 3),
        ("6 Monate", 6),
        ("1 Jahr", 12)
    ]
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Modus-Umschalter
                Picker("Suchmodus", selection: $mode) {
                    ForEach(SearchMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.screenMargin)
                .padding(.vertical, AppTheme.spaceXS)
                .background(AppTheme.surface)
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spaceLG) {
                        
                        if mode == .quickQuery {
                            // MARK: - Modus 1: Frage stellen / Datum prüfen
                            VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                                Text("BEI WEM SIND DIE KINDER?")
                                    .font(AppTheme.eyebrow)
                                    .kerning(1.2)
                                    .foregroundStyle(AppTheme.textSecondary)
                                
                                Text("Wähle ein beliebiges Datum oder tippe auf eine Beispielfrage.")
                                    .font(AppTheme.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            
                            // Datums-Auswahl
                            VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                                DatePicker(
                                    "Stichtag prüfen",
                                    selection: $specificTargetDate,
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.graphical)
                                .padding(AppTheme.spaceSM)
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                                .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).strokeBorder(AppTheme.border, lineWidth: 1))
                                .onChange(of: specificTargetDate) { _, newDate in
                                    evaluateTargetDate(newDate)
                                }
                            }
                            
                            // Berechnete Antwort
                            if let answer = queryResultAnswer {
                                TargetDateAnswerCard(
                                    date: specificTargetDate,
                                    info: store.infoForDay(date: specificTargetDate),
                                    answerText: answer,
                                    onOpenDay: { selectedDateForDaySheet = specificTargetDate }
                                )
                            }
                            
                            // Schnelle Beispielfragen
                            VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                                Text("BEISPIELFRAGEN")
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                
                                ExampleQuestionPills(onSelectDate: { date in
                                    specificTargetDate = date
                                    evaluateTargetDate(date)
                                })
                            }
                            
                        } else {
                            // MARK: - Modus 2: Wochenend-Finder
                            VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                                Text("WOCHENEND-PLANUNG")
                                    .font(AppTheme.eyebrow)
                                    .kerning(1.2)
                                    .foregroundStyle(AppTheme.textSecondary)
                                
                                Text("Alle kommenden Wochenenden und Zuständigkeiten auf einen Blick.")
                                    .font(AppTheme.subheadline)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            
                            // Filter Elternteil & Zeitraum
                            VStack(spacing: AppTheme.spaceSM) {
                                // Eltern-Filter
                                HStack(spacing: AppTheme.spaceXS) {
                                    Button {
                                        selectedParentFilter = nil
                                    } label: {
                                        Text("Beide Eltern")
                                            .font(AppTheme.footnote)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedParentFilter == nil ? AppTheme.accent : AppTheme.surface)
                                            .foregroundStyle(selectedParentFilter == nil ? Color.white : AppTheme.text)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().strokeBorder(AppTheme.border, lineWidth: selectedParentFilter == nil ? 0 : 1))
                                    }
                                    .buttonStyle(.plain)
                                    
                                    ForEach(store.parents) { parent in
                                        Button {
                                            selectedParentFilter = parent.id
                                        } label: {
                                            HStack(spacing: 4) {
                                                Circle()
                                                    .fill(parent.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor)
                                                    .frame(width: 8, height: 8)
                                                Text(parent.displayName)
                                                    .font(AppTheme.footnote)
                                                    .fontWeight(.medium)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(selectedParentFilter == parent.id ? AppTheme.accent : AppTheme.surface)
                                            .foregroundStyle(selectedParentFilter == parent.id ? Color.white : AppTheme.text)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().strokeBorder(AppTheme.border, lineWidth: selectedParentFilter == parent.id ? 0 : 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                // Zeitraum-Horizonte
                                HStack(spacing: AppTheme.spaceXS) {
                                    ForEach(horizonOptions, id: \.1) { option in
                                        Button {
                                            timeHorizonMonths = option.1
                                        } label: {
                                            Text(option.0)
                                                .font(AppTheme.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(timeHorizonMonths == option.1 ? AppTheme.surfaceSecondary : AppTheme.surface)
                                                .foregroundStyle(AppTheme.text)
                                                .clipShape(Capsule())
                                                .overlay(Capsule().strokeBorder(AppTheme.border, lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            
                            // Liste der Wochenenden
                            let weekends = ScheduleEngine.findWeekends(
                                from: Date(),
                                monthsAhead: timeHorizonMonths,
                                targetParentId: selectedParentFilter,
                                plan: store.activePlan,
                                parents: store.parents,
                                exceptions: store.exceptions
                            )
                            
                            VStack(spacing: AppTheme.spaceXS) {
                                ForEach(0..<weekends.count, id: \.self) { idx in
                                    let item = weekends[idx]
                                    WeekendCardRow(
                                        saturday: item.saturday,
                                        sunday: item.sunday,
                                        parent: item.parent,
                                        isShared: item.isShared,
                                        onTap: {
                                            selectedDateForDaySheet = item.saturday
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(AppTheme.screenMargin)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Bei wem?")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Berechnet (Demo)")
                    }
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .onAppear {
                evaluateTargetDate(specificTargetDate)
            }
            .sheet(item: $selectedDateForDaySheet) { date in
                DayDetailSheet(date: date)
            }
        }
    }
    
    private func evaluateTargetDate(_ date: Date) {
        let info = store.infoForDay(date: date)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM yyyy"
        let dateStr = formatter.string(from: date)
        
        if info.isException {
            queryResultAnswer = "Am \(dateStr) sind die Kinder bei \(info.parent.displayName) (Ausnahme: \(info.exceptionReason ?? "geändert"))."
        } else {
            queryResultAnswer = "Am \(dateStr) sind die Kinder regulär bei \(info.parent.displayName)."
        }
    }
}

// MARK: - Subviews

struct TargetDateAnswerCard: View {
    let date: Date
    let info: DayCareInfo
    let answerText: String
    let onOpenDay: () -> Void
    
    private var parentColor: Color {
        info.parent.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spaceSM) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(parentColor)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(info.parent.initial)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color.white)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Zuständigkeit")
                            .font(AppTheme.eyebrow)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text(info.parent.displayName)
                            .font(AppTheme.title3)
                            .foregroundStyle(AppTheme.text)
                    }
                }
                
                Spacer()
                
                Button("Tag öffnen", action: onOpenDay)
                    .font(AppTheme.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.accent)
            }
            
            Text(answerText)
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.text)
        }
        .padding(AppTheme.spaceMD)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                .strokeBorder(info.isException ? AppTheme.exceptionAccent.opacity(0.5) : AppTheme.border, lineWidth: 1.5)
        )
    }
}

struct ExampleQuestionPills: View {
    let onSelectDate: (Date) -> Void
    
    private var sampleDates: [(String, Date)] {
        var cal = Calendar(identifier: .gregorian)
        var list: [(String, Date)] = []
        
        // Nächstes Wochenende
        if let nextSat = cal.nextDate(after: Date(), matching: DateComponents(weekday: 7), matchingPolicy: .nextTime) {
            list.append(("Dieses Wochenende", nextSat))
        }
        // In 2 Wochen
        if let twoWeeks = cal.date(byAdding: .day, value: 14, to: Date()) {
            list.append(("In 2 Wochen", twoWeeks))
        }
        // Weihnachten 2026
        var xmasComps = DateComponents()
        xmasComps.year = 2026
        xmasComps.month = 12
        xmasComps.day = 24
        if let xmas = cal.date(from: xmasComps) {
            list.append(("Weihnachten 2026", xmas))
        }
        // Silvester 2026
        var nyComps = DateComponents()
        nyComps.year = 2026
        nyComps.month = 12
        nyComps.day = 31
        if let ny = cal.date(from: nyComps) {
            list.append(("Silvester 2026", ny))
        }
        return list
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spaceXS) {
                ForEach(sampleDates, id: \.0) { item in
                    Button {
                        onSelectDate(item.1)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text(item.0)
                                .font(AppTheme.footnote)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.surface)
                        .foregroundStyle(AppTheme.text)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(AppTheme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct WeekendCardRow: View {
    let saturday: Date
    let sunday: Date
    let parent: Parent
    let isShared: Bool
    let onTap: () -> Void
    
    private var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM"
        let satStr = formatter.string(from: saturday)
        let sunStr = formatter.string(from: sunday)
        return "\(satStr) – \(sunStr)"
    }
    
    private var parentColor: Color {
        parent.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.spaceMD) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDateRange)
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.text)
                    Text(isShared ? "Geteiltes Wochenende" : "Komplettes Wochenende")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(parentColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(parent.initial)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(Color.white)
                        )
                    Text(parent.displayName)
                        .font(AppTheme.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.text)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(AppTheme.spaceMD)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                    .strokeBorder(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
