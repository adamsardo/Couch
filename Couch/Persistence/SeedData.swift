import Foundation
import SwiftData

/// Seeds the launch scenario catalog (Marcus) and the micro-drill catalog on first launch.
@MainActor
enum SeedData {
    static func runIfNeeded(container: ModelContainer) {
        let context = container.mainContext
        seedScenarios(in: context)
        seedMicroDrills(in: context)
        try? context.save()
    }

    /// Idempotent helper callable from UI flows (e.g. the personalising loader).
    static func ensureScenariosExist(in context: ModelContext) {
        seedScenarios(in: context)
        seedMicroDrills(in: context)
        try? context.save()
    }

    private static func seedScenarios(in context: ModelContext) {
        let id = ScenarioCatalog.marcus.id
        let descriptor = FetchDescriptor<Scenario>(predicate: #Predicate { $0.id == id })
        if (try? context.fetch(descriptor).first) == nil {
            context.insert(ScenarioCatalog.marcusScenarioModel())
        }
    }

    private static func seedMicroDrills(in context: ModelContext) {
        for seed in MicroDrillCatalog.seeds {
            let id = seed.id
            let descriptor = FetchDescriptor<MicroDrill>(predicate: #Predicate { $0.id == id })
            if (try? context.fetch(descriptor).first) == nil {
                context.insert(MicroDrill(id: seed.id, title: seed.title, body: seed.body, category: seed.category))
            }
        }
    }
}
