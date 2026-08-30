import Foundation
import SwiftUI

// MARK: - Family & Members

public struct Family: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    
    public init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

public struct Parent: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var displayName: String
    public var email: String
    public var initial: String
    public var colorIndex: Int // 0: Parent A, 1: Parent B
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        displayName: String,
        email: String = "",
        initial: String? = nil,
        colorIndex: Int = 0
    ) {
        self.id = id
        self.familyId = familyId
        self.displayName = displayName
        self.email = email
        self.initial = initial ?? String(displayName.prefix(1)).uppercased()
        self.colorIndex = colorIndex
    }
}

public struct Child: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var name: String
    public var dateOfBirth: Date?
    public var active: Bool
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        name: String,
        dateOfBirth: Date? = nil,
        active: Bool = true
    ) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.active = active
    }
}

// MARK: - Care Plan Models

public enum RecurrenceType: String, Codable, CaseIterable {
    case weekly = "weekly"            // 1 Woche Wiederholung
    case biweeklyAB = "biweeklyAB"    // 2 Wochen (A / B)
    case triweekly = "triweekly"      // 3 Wochen (A / B / C)
    case alternatingDays = "alternatingDays" // 7/7, 5/2, 2/2/3
    case customCycle = "customCycle"  // N-Tage Zyklus
    
    public var label: String {
        switch self {
        case .weekly: return "Wöchentlich (7 Tage)"
        case .biweeklyAB: return "2-Wochen-Rhythmus (A / B)"
        case .triweekly: return "3-Wochen-Rhythmus (A / B / C)"
        case .alternatingDays: return "Blockwechsel (z.B. 7/7, 2/2/3)"
        case .customCycle: return "Individueller Zyklus"
        }
    }
}

public struct CarePlanDay: Identifiable, Codable, Hashable {
    public var id: UUID
    public var dayIndex: Int // 0..6 für Wochentage (0=Montag), oder 0..(cycleLength-1)
    public var weekIndex: Int // 0 für Woche A, 1 für Woche B etc.
    public var parentId: UUID
    public var timeFrom: String?
    public var timeTo: String?
    public var overnight: Bool
    
    public init(
        id: UUID = UUID(),
        dayIndex: Int,
        weekIndex: Int = 0,
        parentId: UUID,
        timeFrom: String? = nil,
        timeTo: String? = nil,
        overnight: Bool = true
    ) {
        self.id = id
        self.dayIndex = dayIndex
        self.weekIndex = weekIndex
        self.parentId = parentId
        self.timeFrom = timeFrom
        self.timeTo = timeTo
        self.overnight = overnight
    }
}

public struct CarePlan: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var name: String
    public var startDate: Date
    public var endDate: Date?
    public var recurrenceType: RecurrenceType
    public var cycleWeeks: Int // 1 für wöchentlich, 2 für A/B, etc.
    public var days: [CarePlanDay]
    public var active: Bool
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        name: String,
        startDate: Date,
        endDate: Date? = nil,
        recurrenceType: RecurrenceType = .biweeklyAB,
        cycleWeeks: Int = 2,
        days: [CarePlanDay] = [],
        active: Bool = true
    ) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.recurrenceType = recurrenceType
        self.cycleWeeks = cycleWeeks
        self.days = days
        self.active = active
    }
}

// MARK: - Exceptions & Overrides

public struct PlanException: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var date: Date // normalised to startOfDay
    public var endDate: Date?
    public var childId: UUID? // nil = alle Kinder
    public var parentId: UUID
    public var reason: String?
    public var note: String?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        date: Date,
        endDate: Date? = nil,
        childId: UUID? = nil,
        parentId: UUID,
        reason: String? = nil,
        note: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.familyId = familyId
        self.date = Calendar.current.startOfDay(for: date)
        self.endDate = endDate.map { Calendar.current.startOfDay(for: $0) }
        self.childId = childId
        self.parentId = parentId
        self.reason = reason
        self.note = note
        self.createdAt = createdAt
    }
}

// MARK: - Handover / Transitions

public struct Transition: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var date: Date
    public var fromParentId: UUID
    public var toParentId: UUID
    public var location: String
    public var note: String?
    public var time: String?
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        date: Date,
        fromParentId: UUID,
        toParentId: UUID,
        location: String,
        note: String? = nil,
        time: String? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.date = Calendar.current.startOfDay(for: date)
        self.fromParentId = fromParentId
        self.toParentId = toParentId
        self.location = location
        self.note = note
        self.time = time
    }
}

public struct TransitionRule: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var weekday: Int? // nil = alle Wechsel
    public var location: String
    public var defaultTime: String?
    public var defaultNote: String?
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        weekday: Int? = nil,
        location: String = "Kita",
        defaultTime: String? = "16:00",
        defaultNote: String? = "Nach der Kita"
    ) {
        self.id = id
        self.familyId = familyId
        self.weekday = weekday
        self.location = location
        self.defaultTime = defaultTime
        self.defaultNote = defaultNote
    }
}

// MARK: - Notes & Locations

public struct CareNote: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var childId: UUID?
    public var date: Date? // optional an ein Datum gekoppelt
    public var category: String // "Schule/Kita", "Gesundheit", "Übergabe", "Allgemein"
    public var text: String
    public var createdAt: Date
    public var createdByParentId: UUID
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        childId: UUID? = nil,
        date: Date? = nil,
        category: String = "Allgemein",
        text: String,
        createdAt: Date = Date(),
        createdByParentId: UUID
    ) {
        self.id = id
        self.familyId = familyId
        self.childId = childId
        self.date = date.map { Calendar.current.startOfDay(for: $0) }
        self.category = category
        self.text = text
        self.createdAt = createdAt
        self.createdByParentId = createdByParentId
    }
}

public struct LocationItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var name: String
    public var address: String?
    public var type: String // "Kita", "Schule", "Zuhause", "Aktivität", "Sonstiges"
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        name: String,
        address: String? = nil,
        type: String = "Kita"
    ) {
        self.id = id
        self.familyId = familyId
        self.name = name
        self.address = address
        self.type = type
    }
}

// MARK: - Chat

public struct ChatMessage: Identifiable, Codable, Hashable {
    public var id: UUID
    public var familyId: UUID
    public var senderId: UUID
    public var text: String
    public var createdAt: Date
    public var linkedDate: Date? // Datum, auf das sich die Nachricht bezieht
    public var proposedOverrideParentId: UUID? // Optional für Kalendervorschlag
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        senderId: UUID,
        text: String,
        createdAt: Date = Date(),
        linkedDate: Date? = nil,
        proposedOverrideParentId: UUID? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.senderId = senderId
        self.text = text
        self.createdAt = createdAt
        self.linkedDate = linkedDate.map { Calendar.current.startOfDay(for: $0) }
        self.proposedOverrideParentId = proposedOverrideParentId
    }
}

// MARK: - Computed Day Evaluation Result

public struct DayCareInfo: Identifiable, Hashable {
    public var id: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    public var date: Date
    public var parent: Parent
    public var isException: Bool
    public var exceptionReason: String?
    public var isTransitionDay: Bool
    public var transitionDetails: Transition?
    public var notes: [CareNote]
    public var chatMentionsCount: Int
    
    public init(
        date: Date,
        parent: Parent,
        isException: Bool = false,
        exceptionReason: String? = nil,
        isTransitionDay: Bool = false,
        transitionDetails: Transition? = nil,
        notes: [CareNote] = [],
        chatMentionsCount: Int = 0
    ) {
        self.date = Calendar.current.startOfDay(for: date)
        self.parent = parent
        self.isException = isException
        self.exceptionReason = exceptionReason
        self.isTransitionDay = isTransitionDay
        self.transitionDetails = transitionDetails
        self.notes = notes
        self.chatMentionsCount = chatMentionsCount
    }
}
