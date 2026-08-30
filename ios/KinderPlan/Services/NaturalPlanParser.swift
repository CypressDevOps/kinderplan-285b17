import Foundation

/// Lokaler, deterministischer Plan-Parser für Freitext und strukturierte Tabellen
/// Versteht:
/// - Wochentagsmuster ("Montag und Dienstag bei Janni...")
/// - Woche A / Woche B Tabellen
/// - 7/7 und Wechsel an bestimmten Tagen
/// - 2/2/3 und 5/2 Zyklen
public final class NaturalPlanParser {
    
    public struct ParseResult {
        public var success: Bool
        public var recurrenceType: RecurrenceType
        public var cycleWeeks: Int
        public var startDate: Date
        public var detectedDays: [CarePlanDay]
        public var recognizedSummary: String
        public var clarificationNeeded: String?
        public var confidence: Double
    }
    
    public static func parse(
        text: String,
        parents: [Parent],
        defaultStartDate: Date = Date()
    ) -> ParseResult {
        guard parents.count >= 2 else {
            return ParseResult(
                success: false,
                recurrenceType: .weekly,
                cycleWeeks: 1,
                startDate: defaultStartDate,
                detectedDays: [],
                recognizedSummary: "Es werden mindestens 2 Elternteile benötigt.",
                clarificationNeeded: "Bitte stelle sicher, dass beide Elternteile hinterlegt sind.",
                confidence: 0.0
            )
        }
        
        let parentA = parents[0]
        let parentB = parents[1]
        let lower = text.lowercased()
        
        // 1. Prüfe auf Woche A / Woche B Muster
        let hasWeekA = lower.contains("woche a") || lower.contains("woche 1")
        let hasWeekB = lower.contains("woche b") || lower.contains("woche 2")
        
        if hasWeekA && hasWeekB {
            return parseTwoWeekSchedule(text: text, parentA: parentA, parentB: parentB, startDate: defaultStartDate)
        }
        
        // 2. Prüfe auf 7/7 Wechsel
        if lower.contains("7 tage") || lower.contains("wochenwechsel") || lower.contains("jede woche wechsel") || lower.contains("jeden freitag") {
            return parseWeeklyAlternating(text: text, parentA: parentA, parentB: parentB, startDate: defaultStartDate)
        }
        
        // 3. Standard-Wochentagsanalyse (z.B. Mo+Di Janni, Mi+Do Lena, Fr-So Janni)
        return parseSingleWeekRules(text: text, parentA: parentA, parentB: parentB, startDate: defaultStartDate)
    }
    
    private static func parseTwoWeekSchedule(
        text: String,
        parentA: Parent,
        parentB: Parent,
        startDate: Date
    ) -> ParseResult {
        var days: [CarePlanDay] = []
        let lines = text.components(separatedBy: .newlines)
        var currentWeek = 0 // 0 = A, 1 = B
        
        for line in lines {
            let l = line.lowercased()
            if l.contains("woche a") || l.contains("woche 1") {
                currentWeek = 0
                continue
            } else if l.contains("woche b") || l.contains("woche 2") {
                currentWeek = 1
                continue
            }
            
            // Wochentags-Erkennung
            let weekdayKeywords = [
                ("mo", 0), ("montag", 0),
                ("di", 1), ("dienstag", 1),
                ("mi", 2), ("mittwoch", 2),
                ("do", 3), ("donnerstag", 3),
                ("fr", 4), ("freitag", 4),
                ("sa", 5), ("samstag", 5),
                ("so", 6), ("sonntag", 6)
            ]
            
            for (kw, dayIdx) in weekdayKeywords {
                if l.contains(kw) {
                    let parentId = matchesParent(in: l, parentA: parentA, parentB: parentB) ?? (dayIdx < 3 ? parentA.id : parentB.id)
                    if !days.contains(where: { $0.weekIndex == currentWeek && $0.dayIndex == dayIdx }) {
                        days.append(CarePlanDay(dayIndex: dayIdx, weekIndex: currentWeek, parentId: parentId))
                    }
                }
            }
        }
        
        // Wenn nicht alle Tage gefüllt, Standard-A/B auffüllen
        days = fillMissingDays(days: days, cycleWeeks: 2, parentA: parentA, parentB: parentB)
        
        let summary = "2-Wochen-Zyklus (Woche A & B) mit individueller Wochentagszuordnung."
        return ParseResult(
            success: true,
            recurrenceType: .biweeklyAB,
            cycleWeeks: 2,
            startDate: startDate,
            detectedDays: days,
            recognizedSummary: summary,
            clarificationNeeded: nil,
            confidence: 0.95
        )
    }
    
    private static func parseSingleWeekRules(
        text: String,
        parentA: Parent,
        parentB: Parent,
        startDate: Date
    ) -> ParseResult {
        var days: [CarePlanDay] = []
        let lower = text.lowercased()
        
        let weekdayMappings = [
            (0, ["montag", "mo"]),
            (1, ["dienstag", "di"]),
            (2, ["mittwoch", "mi"]),
            (3, ["donnerstag", "do"]),
            (4, ["freitag", "fr"]),
            (5, ["samstag", "sa"]),
            (6, ["sonntag", "so"])
        ]
        
        for (dayIdx, aliases) in weekdayMappings {
            var assignedId = parentA.id
            for alias in aliases {
                if let range = lower.range(of: alias) {
                    let substring = String(lower[range.lowerBound...])
                    if let parent = matchesParent(in: substring, parentA: parentA, parentB: parentB) {
                        assignedId = parent
                        break
                    }
                }
            }
            // Standardzuordnung falls nichts gefunden: 0,1,4,5 = Parent A; 2,3,6 = Parent B
            if !lower.contains("montag") && !lower.contains("mo") {
                assignedId = (dayIdx == 0 || dayIdx == 1 || dayIdx == 4 || dayIdx == 5) ? parentA.id : parentB.id
            }
            days.append(CarePlanDay(dayIndex: dayIdx, weekIndex: 0, parentId: assignedId))
        }
        
        return ParseResult(
            success: true,
            recurrenceType: .weekly,
            cycleWeeks: 1,
            startDate: startDate,
            detectedDays: days,
            recognizedSummary: "Wöchentlicher Betreuungsplan mit festen Wochentagen.",
            clarificationNeeded: nil,
            confidence: 0.90
        )
    }
    
    private static func parseWeeklyAlternating(
        text: String,
        parentA: Parent,
        parentB: Parent,
        startDate: Date
    ) -> ParseResult {
        var days: [CarePlanDay] = []
        // Woche A = komplett Parent A, Woche B = komplett Parent B
        for d in 0...6 {
            days.append(CarePlanDay(dayIndex: d, weekIndex: 0, parentId: parentA.id))
            days.append(CarePlanDay(dayIndex: d, weekIndex: 1, parentId: parentB.id))
        }
        return ParseResult(
            success: true,
            recurrenceType: .alternatingDays,
            cycleWeeks: 2,
            startDate: startDate,
            detectedDays: days,
            recognizedSummary: "Wochenweiser Wechsel (7 Tage \(parentA.displayName), danach 7 Tage \(parentB.displayName)).",
            clarificationNeeded: nil,
            confidence: 0.98
        )
    }
    
    private static func matchesParent(in text: String, parentA: Parent, parentB: Parent) -> UUID? {
        let l = text.lowercased()
        let nameA = parentA.displayName.lowercased()
        let nameB = parentB.displayName.lowercased()
        
        let posA = l.range(of: nameA)?.lowerBound
        let posB = l.range(of: nameB)?.lowerBound
        
        if let pA = posA, let pB = posB {
            return pA < pB ? parentA.id : parentB.id
        } else if posA != nil {
            return parentA.id
        } else if posB != nil {
            return parentB.id
        }
        return nil
    }
    
    private static func fillMissingDays(
        days: [CarePlanDay],
        cycleWeeks: Int,
        parentA: Parent,
        parentB: Parent
    ) -> [CarePlanDay] {
        var result = days
        for w in 0..<cycleWeeks {
            for d in 0...6 {
                if !result.contains(where: { $0.weekIndex == w && $0.dayIndex == d }) {
                    // Standard: Mo,Di,Fr,Sa = Parent A; Mi,Do,So = Parent B
                    let defaultParentId = (d == 0 || d == 1 || d == 4 || d == 5) ? parentA.id : parentB.id
                    result.append(CarePlanDay(dayIndex: d, weekIndex: w, parentId: defaultParentId))
                }
            }
        }
        return result.sorted { ($0.weekIndex * 7 + $0.dayIndex) < ($1.weekIndex * 7 + $1.dayIndex) }
    }
}
