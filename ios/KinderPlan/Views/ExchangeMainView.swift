import SwiftUI

/// Tab 4: Austausch – Sachlicher Familien-Chat und gemeinsame Notizen für getrennte Eltern.
/// Ermöglicht das Verknüpfen von Nachrichten mit bestimmten Kalendertagen und direkte Übernahme als Ausnahme.
public struct ExchangeMainView: View {
    @Environment(CareStore.self) private var store
    
    public enum ExchangeSection: String, CaseIterable {
        case chat = "Chat"
        case notes = "Notizen"
        case rules = "Übergaberegeln"
    }
    
    @State private var section: ExchangeSection = .chat
    @State private var messageInputText: String = ""
    @State private var linkedDateForMessage: Date? = nil
    @State private var showingDatePicker = false
    @State private var showingAddNoteSheet = false
    @State private var selectedDateForDaySheet: Date?
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Segment-Auswahl
                Picker("Bereich", selection: $section) {
                    ForEach(ExchangeSection.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.screenMargin)
                .padding(.vertical, AppTheme.spaceXS)
                .background(AppTheme.surface)
                
                Divider()
                
                // MARK: - Inhalt je nach Sektion
                Group {
                    switch section {
                    case .chat:
                        FamilyChatContentView(
                            messageText: $messageInputText,
                            linkedDate: $linkedDateForMessage,
                            onSend: {
                                store.sendChatMessage(
                                    text: messageInputText,
                                    linkedDate: linkedDateForMessage
                                )
                                messageInputText = ""
                                linkedDateForMessage = nil
                            },
                            onOpenLinkedDate: { date in
                                selectedDateForDaySheet = date
                            }
                        )
                    case .notes:
                        FamilyNotesListView(
                            onAddNote: { showingAddNoteSheet = true },
                            onOpenLinkedDate: { date in
                                selectedDateForDaySheet = date
                            }
                        )
                    case .rules:
                        TransitionRulesView()
                    }
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Austausch")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.shield")
                        Text("Familie")
                    }
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .sheet(isPresented: $showingAddNoteSheet) {
                AddNoteSheet(date: nil)
            }
            .sheet(item: $selectedDateForDaySheet) { date in
                DayDetailSheet(date: date)
            }
        }
    }
}

// MARK: - Chat Sektion

struct FamilyChatContentView: View {
    @Environment(CareStore.self) private var store
    @Binding var messageText: String
    @Binding var linkedDate: Date?
    let onSend: () -> Void
    let onOpenLinkedDate: (Date) -> Void
    
    @State private var showingDatePickerSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Nachrichtenliste
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: AppTheme.spaceMD) {
                        ForEach(store.chatMessages) { message in
                            ChatMessageBubble(
                                message: message,
                                isFromCurrentUser: message.senderId == store.currentSimulatedParentId,
                                senderName: store.parents.first(where: { $0.id == message.senderId })?.displayName ?? "Elternteil",
                                onOpenDate: {
                                    if let date = message.linkedDate {
                                        onOpenLinkedDate(date)
                                    }
                                },
                                onApplyException: {
                                    if let date = message.linkedDate, let targetParent = message.proposedOverrideParentId {
                                        store.setDayException(
                                            date: date,
                                            parentId: targetParent,
                                            reason: "Aus Chat übernommen",
                                            note: message.text
                                        )
                                    }
                                }
                            )
                            .id(message.id)
                        }
                    }
                    .padding(AppTheme.screenMargin)
                }
            }
            
            // Tag-Verknüpfungs-Banner falls aktiv
            if let date = linkedDate {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "de_DE")
                formatter.dateFormat = "d. MMMM"
                
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(AppTheme.accent)
                    Text("Bezieht sich auf: \(formatter.string(from: date))")
                        .font(AppTheme.caption)
                        .foregroundStyle(AppTheme.text)
                    Spacer()
                    Button {
                        linkedDate = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, AppTheme.screenMargin)
                .padding(.vertical, 6)
                .background(AppTheme.surfaceSecondary)
            }
            
            // Eingabeleiste
            HStack(spacing: AppTheme.spaceXS) {
                Button {
                    showingDatePickerSheet = true
                } label: {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18))
                        .foregroundStyle(linkedDate != nil ? AppTheme.accent : AppTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AppTheme.surfaceSecondary)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                TextField("Nachricht an \(store.currentSimulatedParentId == store.parentA.id ? store.parentB.displayName : store.parentA.displayName)...", text: $messageText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.surfaceSecondary)
                    .clipShape(Capsule())
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.border : AppTheme.accent)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.screenMargin)
            .padding(.vertical, AppTheme.spaceSM)
            .background(AppTheme.surface)
        }
        .sheet(isPresented: $showingDatePickerSheet) {
            ChatLinkDatePickerSheet(selectedDate: $linkedDate)
        }
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    let senderName: String
    let onOpenDate: () -> Void
    let onApplyException: () -> Void
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: message.createdAt)
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 40) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(senderName)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.text)
                        .font(AppTheme.body)
                        .foregroundStyle(isFromCurrentUser ? Color.white : AppTheme.text)
                    
                    if let date = message.linkedDate {
                        let formatter = DateFormatter()
                        formatter.locale = Locale(identifier: "de_DE")
                        formatter.dateFormat = "EEEE, d. MMM"
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11))
                            Text(formatter.string(from: date))
                                .font(AppTheme.caption)
                                .underline()
                        }
                        .foregroundStyle(isFromCurrentUser ? Color.white.opacity(0.9) : AppTheme.accent)
                        .onTapGesture {
                            onOpenDate()
                        }
                    }
                    
                    if message.proposedOverrideParentId != nil {
                        Button(action: onApplyException) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle")
                                Text("Als Änderung eintragen")
                            }
                            .font(AppTheme.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .foregroundStyle(AppTheme.accent)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isFromCurrentUser ? AppTheme.accent : AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isFromCurrentUser ? Color.clear : AppTheme.border, lineWidth: 1)
                )
                
                Text(formattedTime)
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            if !isFromCurrentUser { Spacer(minLength: 40) }
        }
    }
}

struct ChatLinkDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date?
    @State private var pickerDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.spaceMD) {
                DatePicker(
                    "Datum verknüpfen",
                    selection: $pickerDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                Button("Datum an Nachricht anhängen") {
                    selectedDate = pickerDate
                    dismiss()
                }
                .buttonStyle(PrimaryCapsuleButtonStyle())
                .padding(.horizontal, AppTheme.screenMargin)
                
                Spacer()
            }
            .navigationTitle("Tag auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Notizen Sektion

struct FamilyNotesListView: View {
    @Environment(CareStore.self) private var store
    let onAddNote: () -> Void
    let onOpenLinkedDate: (Date) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.spaceMD) {
                HStack {
                    Text("GEMEINSAME NOTIZEN")
                        .font(AppTheme.eyebrow)
                        .kerning(1.2)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                    Button("+ Neue Notiz", action: onAddNote)
                        .font(AppTheme.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.accent)
                }
                .padding(.horizontal, AppTheme.screenMargin)
                .padding(.top, AppTheme.spaceSM)
                
                if store.notes.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("Noch keine Notizen hinterlegt.")
                            .font(AppTheme.footnote)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.spaceXXL)
                } else {
                    VStack(spacing: AppTheme.spaceXS) {
                        ForEach(store.notes) { note in
                            NoteCardItem(
                                note: note,
                                authorName: store.parents.first(where: { $0.id == note.createdByParentId })?.displayName ?? "Elternteil",
                                onOpenDate: {
                                    if let d = note.date {
                                        onOpenLinkedDate(d)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.screenMargin)
                }
            }
            .padding(.bottom, AppTheme.spaceXL)
        }
    }
}

struct NoteCardItem: View {
    let note: CareNote
    let authorName: String
    let onOpenDate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(note.category)
                    .font(AppTheme.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.surfaceSecondary)
                    .foregroundStyle(AppTheme.accent)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("von \(authorName)")
                    .font(AppTheme.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Text(note.text)
                .font(AppTheme.body)
                .foregroundStyle(AppTheme.text)
            
            if let date = note.date {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "de_DE")
                formatter.dateFormat = "d. MMMM yyyy"
                
                Button(action: onOpenDate) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text("Gilt für: \(formatter.string(from: date))")
                            .font(AppTheme.footnote)
                            .underline()
                    }
                    .foregroundStyle(AppTheme.accent)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
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
}

// MARK: - Übergaberegeln Sektion

struct TransitionRulesView: View {
    @Environment(CareStore.self) private var store
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spaceLG) {
                VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                    Text("STANDARD-ÜBERGABEN")
                        .font(AppTheme.eyebrow)
                        .kerning(1.2)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    Text("Hier werden die gewohnten Routinen für Betreuungswechsel hinterlegt.")
                        .font(AppTheme.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                VStack(spacing: AppTheme.spaceSM) {
                    ForEach(store.transitionRules) { rule in
                        HStack(spacing: AppTheme.spaceMD) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 22))
                                .foregroundStyle(AppTheme.accent)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(rule.location)
                                    .font(AppTheme.headline)
                                    .foregroundStyle(AppTheme.text)
                                Text("\(rule.defaultNote ?? "Nach der Kita") · \(rule.defaultTime ?? "16:00") Uhr")
                                    .font(AppTheme.footnote)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(AppTheme.spaceMD)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).strokeBorder(AppTheme.border, lineWidth: 1))
                    }
                }
                
                // Gespeicherte Orte
                VStack(alignment: .leading, spacing: AppTheme.spaceXS) {
                    Text("BEKANNTE ORTE")
                        .font(AppTheme.eyebrow)
                        .kerning(1.2)
                        .foregroundStyle(AppTheme.textSecondary)
                    
                    VStack(spacing: AppTheme.spaceXS) {
                        ForEach(store.locations) { loc in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(loc.name)
                                        .font(AppTheme.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.text)
                                    if let addr = loc.address {
                                        Text(addr)
                                            .font(AppTheme.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                }
                                Spacer()
                                Text(loc.type)
                                    .font(AppTheme.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(AppTheme.spaceSM)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard))
                            .overlay(RoundedRectangle(cornerRadius: AppTheme.radiusCard).strokeBorder(AppTheme.border, lineWidth: 1))
                        }
                    }
                }
            }
            .padding(AppTheme.screenMargin)
        }
    }
}
