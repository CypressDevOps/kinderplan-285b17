import SwiftUI

/// Tab 1: Beantwortet die zentrale Frage der Eltern innerhalb einer Sekunde nach dem Start.
/// Zeigt den heutigen Betreuer, Übergabeort & Zeit, nächsten Wechsel, Vorschau der nächsten Tage und Schnellaktionen.
public struct TodayView: View {
    @Environment(CareStore.self) private var store
    @State private var selectedDateForSheet: Date?
    @State private var showingImportSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingSearchSheet = false
    
    private var todayInfo: DayCareInfo {
        store.infoForDay(date: Date())
    }
    
    private var nextTransition: (transitionDate: Date, toParent: Parent, daysUntil: Int)? {
        ScheduleEngine.findNextTransition(
            from: Date(),
            plan: store.activePlan,
            parents: store.parents,
            exceptions: store.exceptions
        )
    }
    
    private var currentActiveChildName: String {
        if let id = store.selectedChildId, let child = store.children.first(where: { $0.id == id }) {
            return child.name
        }
        return store.children.map(\.name).joined(separator: ", ")
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.spaceXL) {
                    
                    // MARK: - Kinder-Auswahl & Demo-Hinweis
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BETREUUNG HEUTE")
                                .font(AppTheme.eyebrow)
                                .kerning(1.2)
                                .foregroundStyle(AppTheme.textSecondary)
                            
                            HStack(spacing: 6) {
                                Text(currentActiveChildName.isEmpty ? "Emma" : currentActiveChildName)
                                    .font(AppTheme.headline)
                                    .foregroundStyle(AppTheme.text)
                                
                                if store.children.count > 1 {
                                    Menu {
                                        Button("Alle Kinder") { store.selectedChildId = nil }
                                        ForEach(store.children) { child in
                                            Button(child.name) { store.selectedChildId = child.id }
                                        }
                                    } label: {
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Switcher für simulierten Elternteil (Demo)
                        Button {
                            store.switchSimulatedParent()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "person.circle")
                                Text("Aktiv: \(store.currentSimulatedParentId == store.parentA.id ? store.parentA.displayName : store.parentB.displayName)")
                                    .font(AppTheme.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.surfaceSecondary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(AppTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppTheme.screenMargin)
                    .padding(.top, AppTheme.spaceXS)
                    
                    // MARK: - Hero: Bei wem sind die Kinder heute?
                    TodayHeroCard(
                        info: todayInfo,
                        onTapChange: { selectedDateForSheet = Date() }
                    )
                    .padding(.horizontal, AppTheme.screenMargin)
                    
                    // MARK: - Übergabe & Nächster Wechsel Status
                    HStack(spacing: AppTheme.spaceMD) {
                        // Nächster Wechsel
                        VStack(alignment: .leading, spacing: AppTheme.spaceXXS) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                                Text("NÄCHSTER WECHSEL")
                                    .font(AppTheme.eyebrow)
                                    .kerning(1.0)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            
                            if let next = nextTransition {
                                Text(formatTransitionDate(next.transitionDate))
                                    .font(AppTheme.title3)
                                    .foregroundStyle(AppTheme.text)
                                    .lineLimit(1)
                                
                                Text("zu \(next.toParent.displayName) (in \(next.daysUntil) \(next.daysUntil == 1 ? "Tag" : "Tagen"))")
                                    .font(AppTheme.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                            } else {
                                Text("Kein Wechsel")
                                    .font(AppTheme.title3)
                                    .foregroundStyle(AppTheme.text)
                                Text("Plan läuft durchgehend")
                                    .font(AppTheme.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                        .padding(AppTheme.spaceMD)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                                .strokeBorder(AppTheme.border, lineWidth: 1)
                        )
                        
                        // Übergabe
                        VStack(alignment: .leading, spacing: AppTheme.spaceXXS) {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppTheme.accent)
                                Text("ÜBERGABE")
                                    .font(AppTheme.eyebrow)
                                    .kerning(1.0)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            
                            Text(store.transitionRules.first?.location ?? "Kita")
                                .font(AppTheme.title3)
                                .foregroundStyle(AppTheme.text)
                                .lineLimit(1)
                            
                            Text(store.transitionRules.first?.defaultNote ?? "Nach der Kita · 16:00")
                                .font(AppTheme.footnote)
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(AppTheme.spaceMD)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                                .strokeBorder(AppTheme.border, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AppTheme.screenMargin)
                    
                    // MARK: - Vorschau der nächsten 5 Tage
                    VStack(alignment: .leading, spacing: AppTheme.spaceSM) {
                        Text("VORSCHAU")
                            .font(AppTheme.eyebrow)
                            .kerning(1.2)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, AppTheme.screenMargin)
                        
                        UpcomingDaysStrip(
                            onSelectDate: { date in
                                selectedDateForSheet = date
                            }
                        )
                    }
                    
                    // MARK: - Schnellaktionen
                    VStack(alignment: .leading, spacing: AppTheme.spaceSM) {
                        Text("SCHNELLAKTIONEN")
                            .font(AppTheme.eyebrow)
                            .kerning(1.2)
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, AppTheme.screenMargin)
                        
                        QuickActionsGrid(
                            onChangeToday: { selectedDateForSheet = Date() },
                            onNewPlan: { showingImportSheet = true },
                            onSearch: { showingSearchSheet = true }
                        )
                        .padding(.horizontal, AppTheme.screenMargin)
                    }
                    
                    // MARK: - Transparenz-Hinweis (Capability Contract)
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        Text("Demo – lokal, noch keine Cloud-Synchronisierung")
                            .font(AppTheme.caption)
                    }
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.vertical, AppTheme.spaceXS)
                    .padding(.bottom, AppTheme.spaceLG)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Heute")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(AppTheme.text)
                    }
                }
            }
            .sheet(item: $selectedDateForSheet) { date in
                DayDetailSheet(date: date)
            }
            .sheet(isPresented: $showingImportSheet) {
                PlanImportSheet()
            }
            .sheet(isPresented: $showingSettingsSheet) {
                FamilySettingsSheet()
            }
            .sheet(isPresented: $showingSearchSheet) {
                WhoHasTheKidsSheet()
            }
        }
    }
    
    private func formatTransitionDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInTomorrow(date) {
            return "Morgen"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - Subviews

struct TodayHeroCard: View {
    let info: DayCareInfo
    let onTapChange: () -> Void
    
    private var parentColor: Color {
        info.parent.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor
    }
    
    private var parentBgColor: Color {
        info.parent.colorIndex == 0 ? AppTheme.parentABackground : AppTheme.parentBBackground
    }
    
    private var formattedTodayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: info.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spaceMD) {
            HStack {
                Text(formattedTodayDate.uppercased())
                    .font(AppTheme.eyebrow)
                    .kerning(1.2)
                    .foregroundStyle(AppTheme.textSecondary)
                
                Spacer()
                
                if info.isException {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                        Text("Ausnahme")
                            .font(AppTheme.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.exceptionBackground)
                    .foregroundStyle(AppTheme.exceptionAccent)
                    .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Bei \(info.parent.displayName)")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundStyle(AppTheme.text)
                
                Text(info.isException ? (info.exceptionReason ?? "Abweichung vom regulären Plan") : "Gemäß aktuellem Betreuungsplan")
                    .font(AppTheme.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(parentColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(info.parent.initial)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.white)
                        )
                    
                    Text("\(info.parent.displayName) betreut heute")
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.text)
                }
                
                Spacer()
                
                Button(action: onTapChange) {
                    Text("Tag anpassen")
                        .font(AppTheme.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.surfaceSecondary)
                        .foregroundStyle(AppTheme.text)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, AppTheme.spaceXS)
        }
        .padding(AppTheme.spaceLG)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                .strokeBorder(info.isException ? AppTheme.exceptionAccent.opacity(0.4) : AppTheme.border, lineWidth: 1.5)
        )
    }
}

struct UpcomingDaysStrip: View {
    @Environment(CareStore.self) private var store
    let onSelectDate: (Date) -> Void
    
    private var upcomingDates: [Date] {
        let cal = Calendar.current
        return (1...5).compactMap { cal.date(byAdding: .day, value: $0, to: Date()) }
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spaceSM) {
                ForEach(upcomingDates, id: \.self) { date in
                    let info = store.infoForDay(date: date)
                    UpcomingDayCard(info: info) {
                        onSelectDate(date)
                    }
                }
            }
            .padding(.horizontal, AppTheme.screenMargin)
        }
    }
}

struct UpcomingDayCard: View {
    let info: DayCareInfo
    let action: () -> Void
    
    private var parentColor: Color {
        info.parent.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor
    }
    
    private var weekdayLabel: String {
        let cal = Calendar.current
        if cal.isDateInTomorrow(info.date) {
            return "Morgen"
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "E"
        return formatter.string(from: info.date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d.M."
        return formatter.string(from: info.date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(weekdayLabel)
                    .font(AppTheme.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.textSecondary)
                
                Text(dayNumber)
                    .font(AppTheme.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                
                Circle()
                    .fill(parentColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(info.parent.initial)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.white)
                    )
                
                Text(info.parent.displayName)
                    .font(AppTheme.footnote)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.text)
                    .lineLimit(1)
                
                if info.isException {
                    Circle()
                        .fill(AppTheme.exceptionAccent)
                        .frame(width: 6, height: 6)
                } else {
                    Color.clear.frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, AppTheme.spaceSM)
            .padding(.horizontal, AppTheme.spaceSM)
            .frame(width: 82)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                    .strokeBorder(info.isException ? AppTheme.exceptionAccent.opacity(0.5) : AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionsGrid: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let onChangeToday: () -> Void
    let onNewPlan: () -> Void
    let onSearch: () -> Void
    
    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: AppTheme.spaceMD), count: count)
    }
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.spaceSM) {
            QuickActionButton(
                title: "Tag anpassen",
                subtitle: "Einmalige Ausnahme",
                systemImage: "calendar.badge.clock",
                action: onChangeToday
            )
            
            QuickActionButton(
                title: "Bei wem?",
                subtitle: "Schnellsuche & Fragen",
                systemImage: "magnifyingglass",
                action: onSearch
            )
            
            QuickActionButton(
                title: "Plan importieren",
                subtitle: "Text oder Tabelle",
                systemImage: "square.and.pencil",
                action: onNewPlan
            )
            
            QuickActionButton(
                title: "Wochenenden",
                subtitle: "Wochenend-Finder",
                systemImage: "sun.max",
                action: onSearch
            )
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spaceSM) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.transitionBackground)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
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

// MARK: - Identifiable Date Helper
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
