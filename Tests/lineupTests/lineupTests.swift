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
    
    struct TestingHelper {
        
        // Authentication
        // Create a test token
        static func createTestToken(for userPayload: UserPayload)
        throws -> String {
            let signer = JWTSigner.hs256(key: "MACLESUPERSECRETE")
            return try signer.sign(userPayload)
        }
        // Make a auth header for the requests with our token - has to be the real one!
        static func authHeader(for userPayload: UserPayload)
        throws -> HTTPHeaders {
                let token = try createTestToken(for: userPayload)
                var headers = HTTPHeaders()
                headers.add(name: "Authorization", value: "Bearer \(token)")
                return headers
            }
        static func mockUserPayload() -> UserPayload {
            return UserPayload(id: UUID())
        }
        
        // Create test objects
        static func createTestCategory(
            id: UUID = UUID(),
            name: String = "Test Category"
        )
        throws -> lineup.Category {
            let testCategory = lineup.Category(
                id: id,
                name: name
            )
            return testCategory
        }
        
        static func createTestWorkshop(
            name: String = "Test Workshop",
            startTime: Date = Date(),
            endTime: Date = Date().addingTimeInterval(3600),
            maxCapacity: Int = 20,
            totalSubscribers: Int = 10,
            description: String = "Description of my workshop",
            categoryID: UUID = UUID()
        )
        throws -> Workshop {
            let testWorkshop = Workshop(
                id: UUID(),
                name: name,
                startTime: startTime,
                endTime: endTime,
                maxCapacity: maxCapacity,
                totalSubscribers: totalSubscribers,
                description: description,
                categoryID: categoryID
            )
            return testWorkshop
        }
        
        static func createTestUser(
            name: String = "Tester",
            email: String = "test@email.com",
            password: String = "testPASS1234",
            role: String = "user"
        )
        throws -> User {
            let passwordHash = try Bcrypt.hash(password)
            let testUser = User(
                name: name,
                password: passwordHash,
                email: email,
                role: role,
                createdAt: Date.now
            )
            return testUser
        }
        
        static func createTestReservation(
            id: UUID = UUID(),
            workshopID: UUID = UUID(),
            userID: UUID = UUID(),
            status: String = "confirmed"
        )
        throws -> Reservation {
            let testReservation = Reservation(
                id: UUID(),
                workshop: workshopID,
                user: userID,
                status: status
            )
            return testReservation
        }
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
    
    @Test("Test GET Categories")
    func testGetCategories() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            try await app.testing().test(.GET, "workshops/cate", headers: headers) { res async in
                #expect(res.status == .ok )
            }
        }
    }
    
    @Test("Test Get Workshop With Reservations: without Reservations")
    func testGetWorkshopWithReservationsWithoutReservations() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            try await app.testing().test(
                .GET,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let responseDTO = try res.content.decode(WorkshopWithReservationDTO.self)
                    #expect(responseDTO.workshopDTO.name == testWorkshop.name)
                    #expect(responseDTO.workshopDTO.categoryName == testCategory.name)
                    #expect(responseDTO.reservations.isEmpty)
                }
            )
        }
    }
    
    @Test("Test Get Workshop With Reservations: with Reservations")
    func testGetWorkshopWithReservationsWithReservations() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUser = try TestingHelper.createTestUser()
            try await testUser.save(on: app.db)
            
            let testReservation = try TestingHelper.createTestReservation(
                workshopID: testWorkshop.id!,
                userID: testUser.id!
            )
            try await testReservation.save(on: app.db)
            
            try await app.testing().test(
                .GET,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    let responseDTO = try res.content.decode(WorkshopWithReservationDTO.self)
                    #expect(responseDTO.workshopDTO.name == testWorkshop.name)
                    #expect(responseDTO.workshopDTO.categoryName == testCategory.name)
                    #expect(!responseDTO.reservations.isEmpty)
                }
            )
        }
    }
    
    @Test("Test Get Workshop With Reservations: Invalid UUID format")
    func testGetWorkshopWithReservationsInvalidUUIDFormat() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let invalidWorkshopID = "UUID"
            
            try await app.testing().test(
                .GET,
                "workshops/\(invalidWorkshopID)",
                headers: headers,
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
        }
    }
    
    @Test("Test Get Workshop With Reservations: Workshop Does Not Exist")
    func testGetWorkshopWithReservationsWorkshopDoesNotExist() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let invalidWorkshopID = UUID()
            
            try await app.testing().test(
                .GET,
                "workshops/\(invalidWorkshopID)",
                headers: headers,
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
        }
    }
    
    @Test("Test Get Workshop With Reservations: From User")
    func testGetWorkshopWithReservationsFromUser() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUser = try TestingHelper.createTestUser()
            try await testUser.save(on: app.db)
            
            try await app.testing().test(
                .GET,
                "workshops",
                headers: headers,
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                    #expect(res.content.contentType == .json)
                    let workshops = try res.content.decode([WorkshopDTO].self)
                    #expect(!workshops.isEmpty)
                    #expect(workshops.first?.name == "Test Workshop")
                }
            )
        }
    }
    
    @Test("Test Update Workshop")
    func testUpdateWorkshop() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUpdateWorkshopDTO = UpdateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                totalSubscribers: testWorkshop.totalSubscribers,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .PUT,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testUpdateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .ok)
                }
            )
            return
        }
    }
    
    @Test("Test Update Workshop: Empty Name")
    func testUpdateWorkshopEmptyName() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUpdateWorkshopDTO = UpdateWorkshopDTO(
                name: "",
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                totalSubscribers: testWorkshop.totalSubscribers,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .PUT,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testUpdateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Update Workshop: Invalid End Time")
    func testUpdateWorkshopInvalidEndTime() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUpdateWorkshopDTO = UpdateWorkshopDTO(
                name: testWorkshop.name,
                startTime: Date(),
                endTime: Date(timeIntervalSinceNow: -3600),
                maxCapacity: testWorkshop.maxCapacity,
                totalSubscribers: testWorkshop.totalSubscribers,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .PUT,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testUpdateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Update Workshop: Invalid Max Capacity")
    func testUpdateWorkshopInvalidMaxCapacity() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUpdateWorkshopDTO = UpdateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: 0,
                totalSubscribers: testWorkshop.totalSubscribers,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .PUT,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testUpdateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Update Workshop: Invalid Total Subscribers")
    func testUpdateWorkshopTotalSubscribers() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUpdateWorkshopDTO = UpdateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                totalSubscribers: -1,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .PUT,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testUpdateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Update Workshop: Description Too Short")
    func testUpdateWorkshopDescriptionTooShort() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUpdateWorkshopDTO = UpdateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                totalSubscribers: testWorkshop.totalSubscribers,
                description: "not5",
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .PUT,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testUpdateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Update Workshop: Category Not Found")
    func testUpdateWorkshopCategoryNotFound() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            try await testWorkshop.save(on: app.db)
            
            let testUpdateWorkshopDTO = UpdateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                totalSubscribers: testWorkshop.totalSubscribers,
                description: testWorkshop.description,
                categoryID: UUID()
            )
            
            try await app.testing().test(
                .PUT,
                "workshops/\(testWorkshop.id!)",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testUpdateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
            return
        }
    }
    
    @Test("Test Create Workshop")
    func testCreateWorkshop() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: testCategory.id!)
            
            let testCreateWorkshopDTO = CreateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .POST,
                "workshops",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testCreateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .created)
                }
            )
            return
        }
    }
    
    @Test("Test Create Workshop: Empty Name")
    func testCreateWorkshopEmptyName() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(name: "",categoryID: testCategory.id!)
            
            let testCreateWorkshopDTO = CreateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .POST,
                "workshops",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testCreateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Create Workshop: Invalid End Time")
    func testCreateWorkshopInvalidEndTime() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(startTime: Date(), endTime: Date(timeIntervalSinceNow: -3600), categoryID: testCategory.id!)
            
            let testCreateWorkshopDTO = CreateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .POST,
                "workshops",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testCreateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Create Workshop: Invalid Start Time Type")
    func testCreateWorkshopInvalidStartTimeType() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let rawJSON = """
            {
                "name": "Test Workshop",
                "startTime": "wrong type",
                "endTime": 999999999,
                "maxCapacity": 20,
                "description": "Description of my workshop",
                "categoryID": "\(testCategory.id!)"
            }
            """
            
            try await app.testing().test(
                .POST,
                "workshops",
                headers: headers,
                beforeRequest: { req in
                    req.body.writeString(rawJSON)
                    req.headers.contentType = .json
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Create Workshop: Invalid End Time Type")
    func testCreateWorkshopInvalidEndTimeType() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let rawJSON = """
            {
                "name": "Test Workshop",
                "startTime": 999999999,
                "endTime": "wrong-type",
                "maxCapacity": 20,
                "description": "Description of my workshop",
                "categoryID": "\(testCategory.id!)"
            }
            """
            
            try await app.testing().test(
                .POST,
                "workshops",
                headers: headers,
                beforeRequest: { req in
                    req.body.writeString(rawJSON)
                    req.headers.contentType = .json
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Create Workshop: Invalid Maximum Capacity")
    func testCreateWorkshopInvalidMaximumCapacity() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(maxCapacity: 0, categoryID: testCategory.id!)
            
            let testCreateWorkshopDTO = CreateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .POST,
                "workshops",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testCreateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Create Workshop: Description Too Short")
    func testCreateWorkshopDescriptionTooShort() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(description: "bad", categoryID: testCategory.id!)
            
            let testCreateWorkshopDTO = CreateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .POST,
                "workshops",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testCreateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .badRequest)
                }
            )
            return
        }
    }
    
    @Test("Test Create Workshop: Invalid Category")
    func testCreateWorkshopInvalidCategory() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testCategory = try TestingHelper.createTestCategory()
            try await testCategory.save(on: app.db)
            
            let testWorkshop = try TestingHelper.createTestWorkshop(categoryID: UUID())
            
            let testCreateWorkshopDTO = CreateWorkshopDTO(
                name: testWorkshop.name,
                startTime: testWorkshop.startTime,
                endTime: testWorkshop.endTime,
                maxCapacity: testWorkshop.maxCapacity,
                description: testWorkshop.description,
                categoryID: testWorkshop.$category.id
            )
            
            try await app.testing().test(
                .POST,
                "workshops",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(testCreateWorkshopDTO)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
            return
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
            
            try await app.testing().test(
                .POST,
                "login",
                beforeRequest: { req in
                    try req.content.encode(loginCreds)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
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
            
            try await app.testing().test(
                .POST,
                "login",
                beforeRequest: { req in
                    try req.content.encode(loginCreds)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
            return
        }
    }
    
    @Test("Test Login: Admin")
    func testLoginAdmin() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testUser = try TestingHelper.createTestUser(role: "admin")
            try await testUser.save(on: app.db)
            
            let loginCreds = LoginRequestDTO(email: "test@email.com", password: "testPASS1234")
            var token = ""
            
            try await app.testing().test(
                .POST,
                "login/admin",
                headers: headers,
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
    
    @Test("Test Login: Admin Wrong Role")
    func testLoginAdminWrongRole() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testUser = try TestingHelper.createTestUser()
            try await testUser.save(on: app.db)
            
            let loginCreds = LoginRequestDTO(email: "test@email.com", password: "testPASS1234")
            
            try await app.testing().test(
                .POST,
                "login/admin",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(loginCreds)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
            return
        }
    }
    
    @Test("Test Login: Admin Wrong Email")
    func testLoginAdminWrongEmail() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testUser = try TestingHelper.createTestUser(role: "admin")
            try await testUser.save(on: app.db)
            
            let loginCreds = LoginRequestDTO(email: "wrong@email.com", password: "testPASS1234")
            
            try await app.testing().test(
                .POST,
                "login/admin",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(loginCreds)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
            return
        }
    }
    
    @Test("Test Login: Admin Wrong Password")
    func testLoginAdminWrongPassword() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            let testUser = try TestingHelper.createTestUser(role: "admin")
            try await testUser.save(on: app.db)
            
            let loginCreds = LoginRequestDTO(email: "wrong@email.com", password: "testWRONG1234")
            
            try await app.testing().test(
                .POST,
                "login/admin",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(loginCreds)
                },
                afterResponse: { res async throws in
                    #expect(res.status == .notFound)
                }
            )
            return
        }
    }
    
    // "register" - create User
    @Test("Test Register")
    func testRegister() async throws {
        try await withApp { app in

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
    /*
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
    */
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
    
    // TESTS - RESERVATION CONTROLLER
    /*
    import Fluent
    import Vapor
    struct ReservationController: RouteCollection{
        func boot(routes: any RoutesBuilder) throws {
            let reservations = routes.grouped("reservations")
            
            reservations.get(use: getAll)
            reservations.get(":id", use: getOneById)
            
            let privateRoutes = reservations.grouped(JWTMiddleware())
            privateRoutes.post("participate", use: participate)

            privateRoutes.delete("cancel",":id", use: cancel)
        }
     MISSING routes
     
     The final section left to implement in your test suite is the ReservationController. You need to write tests for these remaining endpoints:
     GET /reservations (getAll)
     GET /reservations/:id (getOneById)
     POST /reservations/participate (Protected route - test success and failure when participating in a workshop)
     DELETE /reservations/cancel/:id (Protected route - test successfully canceling a reservation and handling missing/unauthorized cases)
     
    */
    @Test("Test GET Reservations")
    func testGetReservations() async throws {
        try await withApp { app in
            let user = TestingHelper.mockUserPayload()
            let headers = try TestingHelper.authHeader(for: user)
            
            try await app.testing().test(.GET, "reservations", headers: headers) { res async in
                #expect(res.status == .ok )
            }
        }
    }
    
}
