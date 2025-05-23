import SwiftUI
import FirebaseCore

@main
struct ArrowMarkApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                BasicInfoView()
                    .tabItem { Label("入力", systemImage: "square.and.pencil") }
                SettingsView()
                    .tabItem { Label("設定", systemImage: "gear") }
            }
            .environment(\.managedObjectContext,
                         persistenceController.container.viewContext)
//            .onAppear {
//                SettingsSeeder.initializeIfNeeded(
//                    context: persistenceController.container.viewContext)
//            }
        }
    }
}
