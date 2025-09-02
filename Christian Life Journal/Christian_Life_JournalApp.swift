import SwiftUI
import SwiftData
import CloudKit

@main
struct YourApp: App {
    @StateObject private var authService = BiometricAuthService.shared
    
    // Create container once at startup, don't make it reactive to UserDefaults changes
    private let modelContainer: ModelContainer = {
        // Read CloudKit setting once at startup from the centralized service
        let cloudKitEnabled = CloudKitSettingsService.shared.cloudKitEnabled
        
        return createModelContainer(cloudKitEnabled: cloudKitEnabled)
    }()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // App going to background - require re-authentication
                    authService.logout()
                }
        }
        .modelContainer(modelContainer)
    }
    
    private static func createModelContainer(cloudKitEnabled: Bool) -> ModelContainer {
        let schema = Schema([
            JournalEntry.self,
            ScriptureMemoryEntry.self,
            Tag.self,
            Speaker.self,
            PrayerRequest.self,
            PrayerCategory.self,
            Binder.self
        ])
        
        let modelConfiguration: ModelConfiguration
        
        if cloudKitEnabled {
            // CloudKit-enabled configuration
            #if canImport(CloudKit)
            if #available(iOS 17.0, *) {
                modelConfiguration = ModelConfiguration(
                    "iCloud.colbyacorcoran.Christian-Life-Journal",
                    schema: schema
                )
            } else {
                // Fallback for older iOS versions
                modelConfiguration = ModelConfiguration(schema: schema)
            }
            #else
            // CloudKit not available, use local storage
            modelConfiguration = ModelConfiguration(schema: schema)
            #endif
        } else {
            // Local-only configuration
            modelConfiguration = ModelConfiguration(schema: schema)
        }
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Fallback to local-only if CloudKit fails
            print("ModelContainer creation failed, falling back to local storage: \(error)")
            
            // Force disable CloudKit and try local-only
            UserDefaults.standard.set(false, forKey: "cloudKitEnabled")
            
            do {
                let fallbackConfig = ModelConfiguration(schema: schema)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                print("Fallback ModelContainer creation also failed: \(error)")
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }
}

// And create a ContentView that initializes the stores with modelContext
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = BiometricAuthService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    
    var body: some View {
        Group {
            if authService.requiresAuthentication() {
                AuthenticationView()
                    .environmentObject(authService)
            } else {
                DashboardView()
                    .environmentObject(TagStore(modelContext: modelContext))
                    .environmentObject(SpeakerStore(modelContext: modelContext))
                    .environmentObject(BinderStore(modelContext: modelContext))
                    .environmentObject(PrayerCategoryStore(modelContext: modelContext))
                    .environmentObject(PrayerRequestStore(modelContext: modelContext))
                    .environmentObject(authService)
            }
        }
        .onAppear {
            analyticsService.trackAppLaunched()
            analyticsService.trackDailyActiveUser()
            analyticsService.trackUserRetention()
        }
    }
}
