import SwiftUI

@main
struct KinderPlanApp: App {
    @State private var careStore = CareStore()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(careStore)
                .preferredColorScheme(.light) // Pinned light per clinical cal-ai style
        }
    }
}

/// Haupt-Tab-Navigation von KinderPlan mit den 4 fokussierten Bereichen:
/// 1. Heute – Sofortige Orientierung (Bei wem sind die Kinder heute?)
/// 2. Kalender – Monats-, Wochen- und Mehrjahresübersicht
/// 3. Bei wem? – Zukunftsfragen & strukturierter Wochenend-Finder
/// 4. Austausch – Familien-Chat & Notizen
struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Heute", systemImage: "sun.max.fill")
                }
                .tag(0)
            
            CalendarMainView()
                .tabItem {
                    Label("Kalender", systemImage: "calendar")
                }
                .tag(1)
            
            WhoHasTheKidsSheet()
                .tabItem {
                    Label("Bei wem?", systemImage: "magnifyingglass")
                }
                .tag(2)
            
            ExchangeMainView()
                .tabItem {
                    Label("Austausch", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.accent)
    }
}
