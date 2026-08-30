import SwiftUI

/// Tab 2: Der zentrale Kalender für KinderPlan mit Monatsansicht, Wochenansicht und Mehrjahres-Berechnung.
/// Klare visuelle Unterscheidung der Eltern über dezente Farben und Initialen; barrierearm und ohne überladene Elemente.
public struct CalendarMainView: View {
    @Environment(CareStore.self) private var store
    
    public enum CalendarViewMode: String, CaseIterable {
        case month = "Monat"
        case week = "Woche"
        case year = "Jahre"
    }
    
    @State private var viewMode: CalendarViewMode = .month
    @State private var displayedMonth: Date = Date()
    @State private var selectedDateForDetail: Date?
    @State private var showingImportSheet = false
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Montag
        return cal
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - View Mode & Filter Leiste
                HStack {
                    Picker("Ansicht", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if store.children.count > 1 {
                        Menu {
                            Button("Alle Kinder") { store.selectedChildId = nil }
                            ForEach(store.children) { child in
                                Button(child.name) { store.selectedChildId = child.id }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(store.selectedChildId == nil ? "Alle" : (store.children.first(where: { $0.id == store.selectedChildId })?.name ?? "Kind"))
                                    .font(AppTheme.caption)
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppTheme.surfaceSecondary)
                            .foregroundStyle(AppTheme.text)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, AppTheme.screenMargin)
                .padding(.vertical, AppTheme.spaceXS)
                .background(AppTheme.surface)
                
                Divider()
                
                // MARK: - Legende (Elternfarben & Status)
                CalendarLegendView(parentA: store.parentA, parentB: store.parentB)
                    .padding(.horizontal, AppTheme.screenMargin)
                    .padding(.vertical, AppTheme.spaceXS)
                    .background(AppTheme.background)
                
                // MARK: - Inhalt je nach Modus
                Group {
                    switch viewMode {
                    case .month:
                        MonthCalendarContentView(
                            displayedMonth: $displayedMonth,
                            onSelectDate: { date in
                                selectedDateForDetail = date
                            }
                        )
                    case .week:
                        WeekCalendarContentView(
                            baseDate: displayedMonth,
                            onSelectDate: { date in
                                selectedDateForDetail = date
                            }
                        )
                    case .year:
                        MultiYearOverviewView(
                            onSelectMonth: { monthDate in
                                displayedMonth = monthDate
                                viewMode = .month
                            }
                        )
                    }
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Kalender")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        displayedMonth = Date()
                    } label: {
                        Text("Heute")
                            .font(AppTheme.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.accent)
                    }
                }
            }
            .sheet(item: $selectedDateForDetail) { date in
                DayDetailSheet(date: date)
            }
            .sheet(isPresented: $showingImportSheet) {
                PlanImportSheet()
            }
        }
    }
}

// MARK: - Legende

struct CalendarLegendView: View {
    let parentA: Parent
    let parentB: Parent
    
    var body: some View {
        HStack(spacing: AppTheme.spaceMD) {
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.parentAColor)
                    .frame(width: 10, height: 10)
                Text(parentA.displayName)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.text)
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.parentBColor)
                    .frame(width: 10, height: 10)
                Text(parentB.displayName)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.text)
            }
            
            HStack(spacing: 4) {
                Circle()
                    .fill(AppTheme.exceptionAccent)
                    .frame(width: 8, height: 8)
                Text("Ausnahme")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Monatsansicht

struct MonthCalendarContentView: View {
    @Environment(CareStore.self) private var store
    @Binding var displayedMonth: Date
    let onSelectDate: (Date) -> Void
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Montag
        return cal
    }
    
    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth).capitalized
    }
    
    private var daysInMonthGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstDay = monthInterval.start
        
        let weekday = calendar.component(.weekday, from: firstDay)
        // 2=Mo -> 0 leading empty cells, 1=So -> 6 leading empty cells
        let leadingBlanks = (weekday + 5) % 7
        
        var grid: [Date?] = Array(repeating: nil, count: leadingBlanks)
        
        var cursor = firstDay
        while cursor < monthInterval.end {
            grid.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        
        // Auffüllen auf volle Wochen
        while grid.count % 7 != 0 {
            grid.append(nil)
        }
        return grid
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spaceSM) {
            
            // Monat-Umschalter
            HStack {
                Button {
                    if let prev = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = prev
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(monthTitle)
                    .font(AppTheme.title3)
                    .foregroundStyle(AppTheme.text)
                
                Spacer()
                
                Button {
                    if let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = next
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.screenMargin)
            .padding(.top, AppTheme.spaceXS)
            
            // Wochentags-Kopfzeile
            HStack(spacing: 0) {
                ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { day in
                    Text(day)
                        .font(AppTheme.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, AppTheme.screenMargin)
            
            // Tage-Gitter
            ScrollView {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(0..<daysInMonthGrid.count, id: \.self) { idx in
                        if let date = daysInMonthGrid[idx] {
                            let info = store.infoForDay(date: date)
                            MonthDayCell(
                                info: info,
                                isToday: calendar.isDateInToday(date),
                                action: { onSelectDate(date) }
                            )
                        } else {
                            Color.clear
                                .frame(height: 58)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.screenMargin)
                .padding(.bottom, AppTheme.spaceXL)
            }
        }
    }
}

struct MonthDayCell: View {
    let info: DayCareInfo
    let isToday: Bool
    let action: () -> Void
    
    private var parentColor: Color {
        info.parent.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor
    }
    
    private var parentBgColor: Color {
        info.parent.colorIndex == 0 ? AppTheme.parentABackground : AppTheme.parentBBackground
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: info.date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Obere Zeile: Tagesnummer + Indikatoren
                HStack(spacing: 2) {
                    Text(dayNumber)
                        .font(.system(size: 13, weight: isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? AppTheme.accent : AppTheme.text)
                    
                    Spacer(minLength: 0)
                    
                    if info.isException {
                        Circle()
                            .fill(AppTheme.exceptionAccent)
                            .frame(width: 5, height: 5)
                    }
                    if !info.notes.isEmpty {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 4)
                
                Spacer(minLength: 0)
                
                // Initial des Elternteils
                Text(info.parent.initial)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(parentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(parentBgColor)
                    )
                    .padding(.horizontal, 3)
                    .padding(.bottom, 3)
            }
            .frame(height: 58)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusBadge))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusBadge)
                    .strokeBorder(isToday ? AppTheme.accent : AppTheme.border, lineWidth: isToday ? 2 : 0.8)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wochenansicht

struct WeekCalendarContentView: View {
    @Environment(CareStore.self) private var store
    let baseDate: Date
    let onSelectDate: (Date) -> Void
    
    @State private var weekOffset: Int = 0
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        return cal
    }
    
    private var currentWeekDays: [Date] {
        guard let anchor = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: baseDate),
              let weekInterval = calendar.dateInterval(of: .weekOfYear, for: anchor) else {
            return []
        }
        var days: [Date] = []
        var cursor = weekInterval.start
        for _ in 0..<7 {
            days.append(cursor)
            if let next = calendar.date(byAdding: .day, value: 1, to: cursor) {
                cursor = next
            }
        }
        return days
    }
    
    private var weekHeaderTitle: String {
        guard let first = currentWeekDays.first, let last = currentWeekDays.last else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMM"
        return "\(formatter.string(from: first)) – \(formatter.string(from: last))"
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spaceSM) {
            
            // Wochen-Navigation
            HStack {
                Button {
                    weekOffset -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(weekHeaderTitle)
                    .font(AppTheme.title3)
                    .foregroundStyle(AppTheme.text)
                
                Spacer()
                
                Button {
                    weekOffset += 1
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.screenMargin)
            .padding(.top, AppTheme.spaceXS)
            
            ScrollView {
                VStack(spacing: AppTheme.spaceXS) {
                    ForEach(currentWeekDays, id: \.self) { day in
                        let info = store.infoForDay(date: day)
                        WeekDayRow(
                            info: info,
                            isToday: calendar.isDateInToday(day),
                            action: { onSelectDate(day) }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.screenMargin)
                .padding(.bottom, AppTheme.spaceXL)
            }
        }
    }
}

struct WeekDayRow: View {
    let info: DayCareInfo
    let isToday: Bool
    let action: () -> Void
    
    private var parentColor: Color {
        info.parent.colorIndex == 0 ? AppTheme.parentAColor : AppTheme.parentBColor
    }
    
    private var weekdayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: info.date)
    }
    
    private var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMMM"
        return formatter.string(from: info.date)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spaceMD) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(weekdayName)
                        .font(AppTheme.headline)
                        .foregroundStyle(isToday ? AppTheme.accent : AppTheme.text)
                    Text(dateFormatted)
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                Spacer()
                
                if info.isException {
                    Text("Ausnahme")
                        .font(AppTheme.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.exceptionBackground)
                        .foregroundStyle(AppTheme.exceptionAccent)
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(parentColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(info.parent.initial)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.white)
                        )
                    
                    Text(info.parent.displayName)
                        .font(AppTheme.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.text)
                        .frame(width: 60, alignment: .leading)
                }
            }
            .padding(AppTheme.spaceMD)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard)
                    .strokeBorder(isToday ? AppTheme.accent : AppTheme.border, lineWidth: isToday ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mehrjahresansicht

struct MultiYearOverviewView: View {
    @Environment(CareStore.self) private var store
    let onSelectMonth: (Date) -> Void
    
    @State private var selectedYear: Int = 2026
    
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array(currentYear...(currentYear + 5))
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spaceSM) {
            
            // Jahres-Auswahl
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spaceXS) {
                    ForEach(availableYears, id: \.self) { year in
                        Button {
                            selectedYear = year
                        } label: {
                            Text(String(year))
                                .font(AppTheme.headline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedYear == year ? AppTheme.accent : AppTheme.surface)
                                .foregroundStyle(selectedYear == year ? Color.white : AppTheme.text)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(AppTheme.border, lineWidth: selectedYear == year ? 0 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppTheme.screenMargin)
            }
            .padding(.top, AppTheme.spaceXS)
            
            ScrollView {
                VStack(spacing: AppTheme.spaceMD) {
                    ForEach(1...12, id: \.self) { monthIndex in
                        YearMonthBlock(
                            year: selectedYear,
                            month: monthIndex,
                            onTap: {
                                var comps = DateComponents()
                                comps.year = selectedYear
                                comps.month = monthIndex
                                comps.day = 1
                                if let date = Calendar.current.date(from: comps) {
                                    onSelectMonth(date)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, AppTheme.screenMargin)
                .padding(.bottom, AppTheme.spaceXL)
            }
        }
    }
}

struct YearMonthBlock: View {
    @Environment(CareStore.self) private var store
    let year: Int
    let month: Int
    let onTap: () -> Void
    
    private var monthDate: Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1
        return Calendar.current.date(from: comps) ?? Date()
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "LLLL"
        return formatter.string(from: monthDate).capitalized
    }
    
    private var daysDistribution: (parentACount: Int, parentBCount: Int, total: Int) {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: monthDate) else { return (0, 0, 0) }
        var pA = 0
        var pB = 0
        for day in range {
            var comps = DateComponents()
            comps.year = year
            comps.month = month
            comps.day = day
            if let date = cal.date(from: comps) {
                let info = store.infoForDay(date: date)
                if info.parent.colorIndex == 0 {
                    pA += 1
                } else {
                    pB += 1
                }
            }
        }
        return (pA, pB, range.count)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(monthName)
                        .font(AppTheme.headline)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Text("\(daysDistribution.parentACount)T \(store.parentA.displayName) · \(daysDistribution.parentBCount)T \(store.parentB.displayName)")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                // Fortschritts- bzw. Verteilungsbalken
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        let widthA = daysDistribution.total > 0 ? (CGFloat(daysDistribution.parentACount) / CGFloat(daysDistribution.total)) * geo.size.width : 0
                        let widthB = daysDistribution.total > 0 ? (CGFloat(daysDistribution.parentBCount) / CGFloat(daysDistribution.total)) * geo.size.width : 0
                        
                        Rectangle()
                            .fill(AppTheme.parentAColor)
                            .frame(width: max(0, widthA - 1))
                        
                        Rectangle()
                            .fill(AppTheme.parentBColor)
                            .frame(width: max(0, widthB - 1))
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
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
