import Foundation

/// Rechenmotor für wiederkehrende Betreuungspläne:
/// - Berechnet für jedes Datum deterministisch den zuständigen Elternteil
/// - Unterstützt A/B-Wochen, Wochentagsmuster, N-Wochen-Zyklen, 7/7, 5/2, etc.
/// - Berücksichtigt Startdatum, Enddatum und Priorität von Einzel-Ausnahmen (Overrides)
/// - Berechnet Übergabetage (Transition Days) automatisch
public final class ScheduleEngine {
    
    private static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Montag = 2 in gregorianischem Kalender
        cal.timeZone = TimeZone.current
        return cal
    }
    
    /// Berechnet den Betreuungsstatus für ein bestimmtes Datum unter Berücksichtigung von Plan und Ausnahmen.
    public static func evaluateDay(
        date: Date,
        plan: CarePlan?,
        parents: [Parent],
        exceptions: [PlanException],
        childId: UUID? = nil
    ) -> (parent: Parent, isException: Bool, reason: String?)? {
        guard !parents.isEmpty else { return nil }
        let cal = calendar
        let targetDay = cal.startOfDay(for: date)
        
        // 1. Prüfe auf gezielte Ausnahmen für dieses Datum
        if let matchingException = exceptions.first(where: { exc in
            let excStart = cal.startOfDay(for: exc.date)
            let excEnd = exc.endDate.map { cal.startOfDay(for: $0) } ?? excStart
            let matchesDate = targetDay >= excStart && targetDay <= excEnd
            let matchesChild = exc.childId == nil || exc.childId == childId
            return matchesDate && matchesChild
        }) {
            if let assignedParent = parents.first(where: { $0.id == matchingException.parentId }) {
                return (parent: assignedParent, isException: true, reason: matchingException.reason ?? matchingException.note)
            }
        }
        
        // 2. Ohne Plan: Fallback auf ersten Elternteil
        guard let plan = plan, !plan.days.isEmpty else {
            return (parent: parents[0], isException: false, reason: nil)
        }
        
        let planStart = cal.startOfDay(for: plan.startDate)
        
        // 3. Wenn Datum vor Planstart: Fallback oder erster Zyklus
        if let planEnd = plan.endDate, targetDay > cal.startOfDay(for: planEnd) {
            return (parent: parents[0], isException: false, reason: "Nach Planende")
        }
        
        // 4. Zyklusberechnung
        let assignedParentId = resolveParentId(for: targetDay, plan: plan, planStart: planStart)
        
        if let parent = parents.first(where: { $0.id == assignedParentId }) {
            return (parent: parent, isException: false, reason: nil)
        }
        
        return (parent: parents[0], isException: false, reason: nil)
    }
    
    /// Löst die parentId aus den Wiederholungsregeln des Plans auf
    private static func resolveParentId(for targetDay: Date, plan: CarePlan, planStart: Date) -> UUID {
        let cal = calendar
        
        // Wochentag (0 = Montag, 6 = Sonntag)
        let weekdayComponent = cal.component(.weekday, from: targetDay)
        // gregorian: 1=So, 2=Mo, 3=Di, 4=Mi, 5=Do, 6=Fr, 7=Sa
        let weekdayIndex = (weekdayComponent + 5) % 7 // 0=Mo, 1=Di, 2=Mi, 3=Do, 4=Fr, 5=Sa, 6=So
        
        let cycleWeeks = max(1, plan.cycleWeeks)
        
        // Wochen-Abstand ab planStart (ausgehend vom Montag der jeweiligen Woche)
        guard let startMonday = cal.dateInterval(of: .weekOfYear, for: planStart)?.start,
              let targetMonday = cal.dateInterval(of: .weekOfYear, for: targetDay)?.start else {
            // Fallback auf Tagestabelle
            if let day = plan.days.first(where: { $0.dayIndex == weekdayIndex }) {
                return day.parentId
            }
            return plan.days.first?.parentId ?? UUID()
        }
        
        let diffWeeks = cal.dateComponents([.weekOfYear], from: startMonday, to: targetMonday).weekOfYear ?? 0
        let positiveWeekOffset = (diffWeeks % cycleWeeks + cycleWeeks) % cycleWeeks
        
        // Suche passenden Eintrag für (weekIndex, dayIndex)
        if let matched = plan.days.first(where: { $0.weekIndex == positiveWeekOffset && $0.dayIndex == weekdayIndex }) {
            return matched.parentId
        }
        
        // Fallback: Suche nach beliebigem Wochentag im Plan
        if let dayOnly = plan.days.first(where: { $0.dayIndex == weekdayIndex }) {
            return dayOnly.parentId
        }
        
        return plan.days.first?.parentId ?? UUID()
    }
    
    /// Findet den nächsten Betreuungswechsel ab einem Stichtag
    public static func findNextTransition(
        from date: Date,
        plan: CarePlan?,
        parents: [Parent],
        exceptions: [PlanException],
        maxDaysAhead: Int = 60
    ) -> (transitionDate: Date, toParent: Parent, daysUntil: Int)? {
        let cal = calendar
        guard let current = evaluateDay(date: date, plan: plan, parents: parents, exceptions: exceptions) else {
            return nil
        }
        
        for offset in 1...maxDaysAhead {
            guard let nextDate = cal.date(byAdding: .day, value: offset, to: date),
                  let nextEval = evaluateDay(date: nextDate, plan: plan, parents: parents, exceptions: exceptions) else {
                continue
            }
            if nextEval.parent.id != current.parent.id {
                return (transitionDate: nextDate, toParent: nextEval.parent, daysUntil: offset)
            }
        }
        return nil
    }
    
    /// Berechnet eine Liste aller Wochenenden für einen bestimmten Elternteil in einem Zeitraum
    public static func findWeekends(
        from startDate: Date,
        monthsAhead: Int,
        targetParentId: UUID?, // nil = beide auflisten
        plan: CarePlan?,
        parents: [Parent],
        exceptions: [PlanException]
    ) -> [(saturday: Date, sunday: Date, parent: Parent, isShared: Bool)] {
        let cal = calendar
        guard let endDate = cal.date(byAdding: .month, value: monthsAhead, to: startDate) else { return [] }
        
        var results: [(saturday: Date, sunday: Date, parent: Parent, isShared: Bool)] = []
        var cursor = cal.startOfDay(for: startDate)
        
        while cursor <= endDate {
            let weekday = cal.component(.weekday, from: cursor)
            // 7 = Samstag
            if weekday == 7 {
                let saturday = cursor
                if let sunday = cal.date(byAdding: .day, value: 1, to: saturday) {
                    let satEval = evaluateDay(date: saturday, plan: plan, parents: parents, exceptions: exceptions)
                    let sunEval = evaluateDay(date: sunday, plan: plan, parents: parents, exceptions: exceptions)
                    
                    if let satParent = satEval?.parent, let sunParent = sunEval?.parent {
                        let isShared = satParent.id != sunParent.id
                        
                        if let targetId = targetParentId {
                            if satParent.id == targetId || sunParent.id == targetId {
                                results.append((saturday: saturday, sunday: sunday, parent: satParent, isShared: isShared))
                            }
                        } else {
                            results.append((saturday: saturday, sunday: sunday, parent: satParent, isShared: isShared))
                        }
                    }
                }
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        
        return results
    }
}
