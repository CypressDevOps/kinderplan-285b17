import SwiftUI

/// Sheet: Familie & Einstellungen mit Verwaltung von Elternprofilen, Kindern,
/// Übergaberegeln, Demo-Reset und Transparenz über den lokalen Demo-Zustand.
public struct FamilySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CareStore.self) private var store
    
    @State private var showingAddChildAlert = false
    @State private var newChildName = ""
    @State private var parentAName = ""
    @State private var parentBName = ""
    @State private var showingResetConfirmation = false
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Familie & Kinder
                Section(header: Text("Familie")) {
                    Text(store.family.name)
                        .font(AppTheme.headline)
                    
                    ForEach(store.children) { child in
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(AppTheme.accent)
                            Text(child.name)
                            Spacer()
                        }
                    }
                    
                    Button("+ Weiteres Kind hinzufügen") {
                        showingAddChildAlert = true
                    }
                    .foregroundStyle(AppTheme.accent)
                }
                
                // MARK: - Eltern-Profile
                Section(header: Text("Elternteile")) {
                    HStack {
                        Circle()
                            .fill(AppTheme.parentAColor)
                            .frame(width: 14, height: 14)
                        TextField("Name Elternteil 1", text: $parentAName)
                            .onChange(of: parentAName) { _, val in
                                if !val.isEmpty {
                                    store.updateParentName(id: store.parentA.id, newName: val)
                                }
                            }
                    }
                    
                    HStack {
                        Circle()
                            .fill(AppTheme.parentBColor)
                            .frame(width: 14, height: 14)
                        TextField("Name Elternteil 2", text: $parentBName)
                            .onChange(of: parentBName) { _, val in
                                if !val.isEmpty {
                                    store.updateParentName(id: store.parentB.id, newName: val)
                                }
                            }
                    }
                }
                
                // MARK: - Demo-Hinweis & Cloud-Status (Capability Contract)
                Section(header: Text("Cloud & Synchronisierung"), footer: Text("In dieser Version werden alle Eingaben und Änderungen lokal auf diesem Gerät gespeichert.")) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(AppTheme.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lokaler Demo-Modus")
                                .font(AppTheme.subheadline)
                                .fontWeight(.semibold)
                            Text("Demo – lokal, noch keine Cloud-Synchronisierung")
                                .font(AppTheme.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // MARK: - Daten zurücksetzen
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Text("Auf Beispieldaten zurücksetzen")
                    }
                }
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .onAppear {
                parentAName = store.parentA.displayName
                parentBName = store.parentB.displayName
            }
            .alert("Kind hinzufügen", isPresented: $showingAddChildAlert) {
                TextField("Name des Kindes", text: $newChildName)
                Button("Abbrechen", role: .cancel) { newChildName = "" }
                Button("Hinzufügen") {
                    store.addChild(name: newChildName)
                    newChildName = ""
                }
            }
            .confirmationDialog("Zurücksetzen?", isPresented: $showingResetConfirmation) {
                Button("Auf Beispieldaten zurücksetzen", role: .destructive) {
                    store.resetToDemoDefaults()
                }
            } message: {
                Text("Möchtest du alle Ausnahmen löschen und die Standard-Beispieldaten wiederherstellen?")
            }
        }
    }
}
