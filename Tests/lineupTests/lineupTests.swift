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
        
        static func createTestWorkshop(
            name: String = "Test Workshop",
            maxCapacity: Int = 20,
            totalSubscribers: Int = 10,
            description: String = "Description of my workshop"
        )
        throws -> Workshop {
            let testWorkshop = Workshop(
                id: UUID(),
                name: name,
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                maxCapacity: maxCapacity,
                totalSubscribers: totalSubscribers,
                description: description,
                categoryID: UUID()
            )
            return testWorkshop
        }
        
        static func createTestUser(
            name: String = "Tester",
            email: String = "test@email.com",
            password: String = "testPASS1234"
        )
        throws -> User {
            let passwordHash = try Bcrypt.hash(password)
            let testUser = User(
                name: name,
                password: passwordHash,
                email: email,
                role: "user",
                createdAt: Date.now
            )
            return testUser
        }
    }
    
    // TESTS - WORKSHOP CONTROLLER
    
    /*
     let path = routes.grouped("workshops")
     path.get("", use: index) --> done
     path.post("", use: createWorkshop) --> doing

     path.group(":id") { pathId in
         pathId.get(use: getWorkshopWithReservation)
         pathId.put(use: editWorkshop)
     }
     
     path.get("cate", use: catIndex)
     
     path.grouped(JWTMiddleware())
         .get("reservations", use: getReservedWorkshopFromUser)
     */
    
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
    
    // Test - /login
    @Test("Test Login")
    func testLogin() async throws {
        try await withApp { app in
            
            let testUser = try TestingHelper.createTestUser()
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
    
    
    @Test("Test Login: Wrong Password")
    func testLoginWrongPassword() async throws {
        try await withApp { app in

            let testUser = try TestingHelper.createTestUser()
            try await testUser.save(on: app.db)
            
            let loginCreds = LoginRequestDTO(email: "test@email.com", password: "testWRONG1234")
            var token = ""
            
            try await app.testing().test(
                .POST,
                "login",
                beforeRequest: { req in
                    try req.content.encode(loginCreds)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                    #expect(token.isEmpty)
                }
            )
            return
        }
    }
    
    @Test("Test Login: Wrong Email")
    func testLoginWrongEmail() async throws {
        try await withApp { app in
            
            let testUser = try TestingHelper.createTestUser()
            try await testUser.save(on: app.db)
            
            let loginCreds = LoginRequestDTO(email: "testWrong@email.com", password: "testPASS1234")
            var token = ""
            
            try await app.testing().test(
                .POST,
                "login",
                beforeRequest: { req in
                    try req.content.encode(loginCreds)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                    #expect(token.isEmpty)
                }
            )
            return
        }
    }
    
    // "register" - create User
    @Test("Test Register")
    func testRegister() async throws {
        try await withApp { app in
            
//            let testUser = try TestingHelper.createTestUser()
//            try await testUser.save(on: app.db)
            
            let sentUser = try TestingHelper.createTestUser()
            
            try await app.testing().test(
                .POST,
                "register",
                beforeRequest: { req in
                    try req.content.encode(sentUser)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )
            return
        }
    }
    
    @Test("Test Register: Duplication")
    func testRegisterDuplication() async throws {
        try await withApp { app in
            
            let testUser = try TestingHelper.createTestUser()
            try await testUser.save(on: app.db)
            
            let sentUser = try TestingHelper.createTestUser()
            
            try await app.testing().test(
                .POST,
                "register",
                beforeRequest: { req in
                    try req.content.encode(sentUser)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .conflict || res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Register: Empty Name")
    func testRegisterEmptyName() async throws {
        try await withApp { app in
            
            let sentUser = try TestingHelper.createTestUser(name: "")
            
            try await app.testing().test(
                .POST,
                "register",
                beforeRequest: { req in
                    try req.content.encode(sentUser)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Register: Name Too Short")
    func testRegisterNameTooShort() async throws {
        try await withApp { app in
            
            let sentUser = try TestingHelper.createTestUser(name: "TS") // <-- has to be at least 3 
            
            try await app.testing().test(
                .POST,
                "register",
                beforeRequest: { req in
                    try req.content.encode(sentUser)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Register: Empty Email")
    func testRegisterEmptyEmail() async throws {
        try await withApp { app in
            
            let sentUser = try TestingHelper.createTestUser(email: "")
            
            try await app.testing().test(
                .POST,
                "register",
                beforeRequest: { req in
                    try req.content.encode(sentUser)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Register: Empty Password")
    func testRegisterEmptyPassword() async throws {
        try await withApp { app in
            
            /* helper does not work here because I hash the password there,
             and it fails to trigger the validation in our route,
             since a hash is created from an empty string anyways,
             I won't create a new helper func just for this,
             I just make one here.
             */
            let invalidPassword = User(
                        name: "Tester",
                        password: "", // <-- the wrong password - Filip
                        email: "test@email.com",
                        role: "user",
                        createdAt: Date()
                        )
            try await app.testing().test(
                .POST,
                "register",
                beforeRequest: { req in
                    try req.content.encode(invalidPassword)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Register: Password Too Short")
    func testRegisterPasswordTooShort() async throws {
        try await withApp { app in
            
            /* helper does not work here because I hash the password there,
             and it fails to trigger the validation in our route,
             since a hash is created from an empty string anyways,
             I won't create a new helper func just for this,
             I just make one here.
             */
            let invalidPassword = User(
                        name: "Tester",
                        password: "1234", // <-- needs to be at least 5 long - Filip
                        email: "test@email.com",
                        role: "user",
                        createdAt: Date()
                        )
            try await app.testing().test(
                .POST,
                "register",
                beforeRequest: { req in
                    try req.content.encode(invalidPassword)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    // Test: profile?? do we even need this route?
    
    
    // TESTS - RESERVATION CONTROLLER
    
}
