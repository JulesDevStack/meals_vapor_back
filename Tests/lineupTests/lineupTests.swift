//
//  lineupTests.swift
//  lineup
//
//  Created by Filip Rizov on 02/11/2026.
//

@testable import lineup
import VaporTesting
import Testing
import Fluent
import JWT
import JWTKit

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
    
    // EXAMPLE TESTS - to delete at end
    @Test("TestExample")
    func testExemple() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "testExample", afterResponse: { res async in
                #expect(true)
            })
        }
    }
    
    @Test("Default")
    func testDefault() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "", afterResponse: { res async in
                #expect(res.body.string == "It works!")
            })
        }
    }
    
    // MOCK DATA for tests
    struct TestingHelper {
        // note: static allows us to use the functions from the struct without an instance
        
        // Authentication
        // Create a test token
        static func createTestToken(for userPayload: UserPayload) throws -> String {
            let signer = JWTSigner.hs256(key: "TestTokenKey")
            return try signer.sign(userPayload)
        }
        // Make a auth header for the requests with our token
        static func authHeader(for userPayload: UserPayload) throws -> HTTPHeaders {
                let token = try createTestToken(for: userPayload)
                var headers = HTTPHeaders()
                headers.add(name: "Authorization", value: "Bearer \(token)")
                return headers
            }
        static func mockUserPayload() -> UserPayload {
            return UserPayload(id: UUID())
        }
        
        // test mock workshops + mock category and reservation TODO
        /*
        static func createMockCategory...
        // use mock cat in mock workshop
        static func createMockWorkshop...
        // use mock user and workshop for the mock reservation
        static func createMockReservation...
         */
    }
    
    // TESTS - WORKSHOP CONTROLLER
    
    @Test("Test GET Workshops")
    func testGetWorkshops() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            try await app.testing().test(.GET, "workshops", headers: headers) { res async in
                #expect(res.status == .ok )
            }
        }
    }
    
    // TESTS - USER CONTROLLER
    
    @Test("Test Login")
    func testLogin() async throws {
        try await withApp { app in
            
            let passwordHash = try Bcrypt.hash("testPASS1234")
            let userMail = "test@email.com"
            
            let testUser = User(name: "", password: passwordHash, email: userMail, role: "USER", createdAt: Date.now)
            try await testUser.save(on: app.db)
            
            let loginCreds = LoginRequestDTO(email: "test@email.com", password: "testPASS1234")
            var token = ""
            
            try await app.testing().test(
                .POST,
                "login",
                beforeRequest: { req in
                    try req.content.encode(loginCreds)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    token = try res.content.decode(AuthDTO.self).token
                    #expect(!token.isEmpty)
                }
            )
            return
        }
    }
    
    // TESTS - RESERVATION CONTROLLER
}

/*
 `
 private func tokenStaff(
         _ app: Application,
         email: String = "staff@test.com",
         password: String = "password123") async throws -> String {
         try await createUserTest(app, email: email, password: password)
         
         let login = LoginRequestDTO(email: email, password: password)
         var token = ""
         
         try await app.testing().test(
             .POST, "users/login",
             beforeRequest: { req in
                 try req.content.encode(login, as: .json)
             },
             afterResponse: { res async throws in
                 token = try res.content.decode(AuthDTO.self).token
             }
         )
         return token
     }
 */
