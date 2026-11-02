@testable import lineup
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct lineupTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    // test example to delete at end
    @Test("TestExample")
    func testExemple() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "testExample", afterResponse: { res async in
                #expect(true)
            })
        }
    }
}
