import Foundation
import SwiftUI

/// Zentraler State Store für KinderPlan mit deterministischer Berechnung,
/// Beispieldaten für Janni, Lena und Emma sowie voller Mutierbarkeit (Ausnahmen, Pläne, Notizen, Chat).
@Observable
public final class CareStore {
    
    // MARK: - State
    public var family: Family
    public var parents: [Parent]
    public var children: [Child]
    public var carePlans: [CarePlan]
    public var activePlanId: UUID?
    public var exceptions: [PlanException]
    public var transitions: [Transition]
    public var transitionRules: [TransitionRule]
    public var notes: [CareNote]
    public var chatMessages: [ChatMessage]
    public var locations: [LocationItem]
    
    public var selectedChildId: UUID? = nil // nil = Alle Kinder
    public var currentSimulatedParentId: UUID // Welcher Elternteil die App bedient
    
    // MARK: - Selected / Active Plan
    public var activePlan: CarePlan? {
        carePlans.first(where: { $0.id == activePlanId && $0.active }) ?? carePlans.first(where: { $0.active })
    }
    
    public var parentA: Parent {
        parents.first ?? Parent(familyId: family.id, displayName: "Janni", colorIndex: 0)
    }
    
    public var parentB: Parent {
        parents.count > 1 ? parents[1] : Parent(familyId: family.id, displayName: "Lena", colorIndex: 1)
    }
    
    public init() {
        let familyId = UUID()
        let pAId = UUID()
        let pBId = UUID()
        let childId = UUID()
        
        let initialFamily = Family(id: familyId, name: "Familie Janni & Lena")
        let parentA = Parent(id: pAId, familyId: familyId, displayName: "Janni", email: "janni@example.com", initial: "J", colorIndex: 0)
        let parentB = Parent(id: pBId, familyId: familyId, displayName: "Lena", email: "lena@example.com", initial: "L", colorIndex: 1)
        let child = Child(id: childId, familyId: familyId, name: "Emma", active: true)
        
        // Initialer Plan ab 01.09.2026 (Demo-Startdatum)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        var startComponents = DateComponents()
        startComponents.year = 2026
        startComponents.month = 9
        startComponents.day = 1
        let planStartDate = cal.date(from: startComponents) ?? Date()
        
        // Woche A & B: Mo, Di -> Janni; Mi, Do -> Lena; Fr, Sa -> Janni; So -> Lena
        var initialDays: [CarePlanDay] = []
        for week in 0...1 {
            initialDays.append(CarePlanDay(dayIndex: 0, weekIndex: week, parentId: pAId)) // Mo
            initialDays.append(CarePlanDay(dayIndex: 1, weekIndex: week, parentId: pAId)) // Di
            initialDays.append(CarePlanDay(dayIndex: 2, weekIndex: week, parentId: pBId)) // Mi
            initialDays.append(CarePlanDay(dayIndex: 3, weekIndex: week, parentId: pBId)) // Do
            initialDays.append(CarePlanDay(dayIndex: 4, weekIndex: week, parentId: pAId)) // Fr
            initialDays.append(CarePlanDay(dayIndex: 5, weekIndex: week, parentId: pAId)) // Sa
            initialDays.append(CarePlanDay(dayIndex: 6, weekIndex: week, parentId: pBId)) // So
        }
        
        let planId = UUID()
        let defaultPlan = CarePlan(
            id: planId,
            familyId: familyId,
            name: "Regulärer Wochenplan",
            startDate: planStartDate,
            endDate: nil,
            recurrenceType: .biweeklyAB,
            cycleWeeks: 2,
            days: initialDays,
            active: true
        )
        
        // Beispiel-Ausnahme: Samstag, 14.11.2026 -> Tausch zu Lena
        var excComponents = DateComponents()
        excComponents.year = 2026
        excComponents.month = 11
        excComponents.day = 14
        let excDate = cal.date(from: excComponents) ?? Date()
        
        let demoException = PlanException(
            familyId: familyId,
            date: excDate,
            childId: nil,
            parentId: pBId,
            reason: "Wochenendtausch",
            note: "Janni ist an diesem Wochenende beruflich unterwegs."
        )
        
        // Standard-Übergaberegel
        let defaultRule = TransitionRule(
            familyId: familyId,
            weekday: nil,
            location: "Kita",
            defaultTime: "16:00",
            defaultNote: "Nach der Kita"
        )
        
        // Initialer Chat
        let msg1 = ChatMessage(
            familyId: familyId,
            senderId: pAId,
            text: "Hallo Lena, ich habe den Betreuungsplan für die nächsten Monate hinterlegt.",
            createdAt: cal.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        )
        let msg2 = ChatMessage(
            familyId: familyId,
            senderId: pBId,
            text: "Super, danke! Passt der Tausch am 14. November für dich?",
            createdAt: cal.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            linkedDate: excDate,
            proposedOverrideParentId: pBId
        )
        let msg3 = ChatMessage(
            familyId: familyId,
            senderId: pAId,
            text: "Ja, ist als Ausnahme für den 14.11. eingetragen! Bitte Schwimmtasche mitgeben.",
            createdAt: cal.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            linkedDate: excDate
        )
        
        // Notizen
        let note1 = CareNote(
            familyId: familyId,
            childId: childId,
            date: excDate,
            category: "Übergabe",
            text: "Schwimmtasche und Turnschuhe mitgeben.",
            createdByParentId: pAId
        )
        let note2 = CareNote(
            familyId: familyId,
            childId: childId,
            date: nil,
            category: "Gesundheit",
            text: "Emma hat am 24.09. Kinderarzt-U3-Folgetermin um 10:30 Uhr.",
            createdByParentId: pBId
        )
        
        // Orte
        let loc1 = LocationItem(familyId: familyId, name: "Kita Sonnenschein", address: "Gartenweg 4", type: "Kita")
        let loc2 = LocationItem(familyId: familyId, name: "Zuhause Janni", address: "Ahornstraße 12", type: "Zuhause")
        let loc3 = LocationItem(familyId: familyId, name: "Zuhause Lena", address: "Lindenallee 8", type: "Zuhause")
        
        self.family = initialFamily
        self.parents = [parentA, parentB]
        self.children = [child]
        self.carePlans = [defaultPlan]
        self.activePlanId = planId
        self.exceptions = [demoException]
        self.transitions = []
        self.transitionRules = [defaultRule]
        self.notes = [note1, note2]
        self.chatMessages = [msg1, msg2, msg3]
        self.locations = [loc1, loc2, loc3]
        self.currentSimulatedParentId = pAId
    }
    
    // MARK: - Evaluation API
    
    public func infoForDay(date: Date) -> DayCareInfo {
        let cal = Calendar.current
        let targetDay = cal.startOfDay(for: date)
        
        let eval = ScheduleEngine.evaluateDay(
            date: targetDay,
            plan: activePlan,
            parents: parents,
            exceptions: exceptions,
            childId: selectedChildId
        )
        
        let assignedParent = eval?.parent ?? parentA
        let isException = eval?.isException ?? false
        let exceptionReason = eval?.reason
        
        // Prüfe ob Betreuungswechsel zum Vortag
        let isTransitionDay: Bool
        if let yesterday = cal.date(byAdding: .day, value: -1, to: targetDay),
           let yesterdayEval = ScheduleEngine.evaluateDay(date: yesterday, plan: activePlan, parents: parents, exceptions: exceptions, childId: selectedChildId) {
            isTransitionDay = yesterdayEval.parent.id != assignedParent.id
        } else {
            isTransitionDay = false
        }
        
        // Notizen für diesen Tag
        let dayNotes = notes.filter { note in
            guard let noteDate = note.date else { return false }
            return cal.isDate(noteDate, inSameDayAs: targetDay)
        }
        
        // Chat-Erwähnungen für diesen Tag
        let chatCount = chatMessages.filter { msg in
            guard let linked = msg.linkedDate else { return false }
            return cal.isDate(linked, inSameDayAs: targetDay)
        }.count
        
        // Spezifische oder generische Übergabe
        let specificTransition = transitions.first(where: { cal.isDate($0.date, inSameDayAs: targetDay) })
        
        return DayCareInfo(
            date: targetDay,
            parent: assignedParent,
            isException: isException,
            exceptionReason: exceptionReason,
            isTransitionDay: isTransitionDay,
            transitionDetails: specificTransition,
            notes: dayNotes,
            chatMentionsCount: chatCount
        )
    }
    
    // MARK: - Mutations
    
    public func setDayException(date: Date, parentId: UUID, reason: String?, note: String?) {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        
        // Entferne eventuell existierende Ausnahme für denselben Tag
        exceptions.removeAll { exc in
            cal.isDate(exc.date, inSameDayAs: startOfDay) && (exc.childId == nil || exc.childId == selectedChildId)
        }
        
        let newExc = PlanException(
            familyId: family.id,
            date: startOfDay,
            childId: selectedChildId,
            parentId: parentId,
            reason: reason,
            note: note
        )
        exceptions.append(newExc)
    }
    
    public func removeException(for date: Date) {
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: date)
        exceptions.removeAll { exc in
            cal.isDate(exc.date, inSameDayAs: startOfDay) && (exc.childId == nil || exc.childId == selectedChildId)
        }
    }
    
    public func addNote(text: String, date: Date? = nil, category: String = "Allgemein", childId: UUID? = nil) {
        let newNote = CareNote(
            familyId: family.id,
            childId: childId,
            date: date,
            category: category,
            text: text,
            createdByParentId: currentSimulatedParentId
        )
        notes.append(newNote)
    }
    
    public func sendChatMessage(text: String, linkedDate: Date? = nil, proposedParentId: UUID? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let msg = ChatMessage(
            familyId: family.id,
            senderId: currentSimulatedParentId,
            text: text,
            linkedDate: linkedDate,
            proposedOverrideParentId: proposedParentId
        )
        chatMessages.append(msg)
    }
    
    public func applyNewPlan(
        name: String,
        startDate: Date,
        recurrenceType: RecurrenceType,
        cycleWeeks: Int,
        days: [CarePlanDay]
    ) {
        // Alten Plan archivieren oder deaktivieren
        for i in 0..<carePlans.count {
            carePlans[i].active = false
        }
        let newPlan = CarePlan(
            familyId: family.id,
            name: name,
            startDate: startDate,
            recurrenceType: recurrenceType,
            cycleWeeks: cycleWeeks,
            days: days,
            active: true
        )
        carePlans.append(newPlan)
        activePlanId = newPlan.id
    }
    
    public func addChild(name: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let newChild = Child(familyId: family.id, name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        children.append(newChild)
    }
    
    public func updateParentName(id: UUID, newName: String) {
        if let idx = parents.firstIndex(where: { $0.id == id }) {
            parents[idx].displayName = newName
            parents[idx].initial = String(newName.prefix(1)).uppercased()
        }
    }
    
    public func switchSimulatedParent() {
        if currentSimulatedParentId == parentA.id {
            currentSimulatedParentId = parentB.id
        } else {
            currentSimulatedParentId = parentA.id
        }
    }
    
    public func resetToDemoDefaults() {
        self.exceptions.removeAll()
        var cal = Calendar(identifier: .gregorian)
        var excComponents = DateComponents()
        excComponents.year = 2026
        excComponents.month = 11
        excComponents.day = 14
        let excDate = cal.date(from: excComponents) ?? Date()
        
        let demoException = PlanException(
            familyId: family.id,
            date: excDate,
            childId: nil,
            parentId: parentB.id,
            reason: "Wochenendtausch",
            note: "Janni ist an diesem Wochenende beruflich unterwegs."
        )
        self.exceptions.append(demoException)
    }
}
