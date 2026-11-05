//
//  UserController.swift
//  MigrateProject
//
//  Created by Apprenant 77 on 29/09/2026.
//

import Fluent
import Vapor
import JWT

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        
        routes.post("login", use: login)
        routes.post("register", use: create)

        let users = routes.grouped("users")
        
        let privateRoutes = users.grouped(JWTMiddleware())
        privateRoutes.get("profile", use: profile)
        
    }
    
    @Sendable
    func create(req: Request) async throws -> UserDTO {
        try CreateUserDTO.validate(content: req)
        var newUser = try req.content.decode(CreateUserDTO.self)
        newUser.password = try Bcrypt.hash(newUser.password)
        let userToSave = newUser.toModel()
        try await userToSave.save(on: req.db)
        return userToSave.toDTO()
    }
    
    @Sendable
    func login(req: Request) async throws -> AuthDTO {
        let userRequest = try req.content.decode(LoginRequestDTO.self)

        guard let userDB = try await User
            .query(on: req.db)
            .filter(\.$email == userRequest.email)
            .first() else {
            throw Abort(.notFound, reason: "Authentification failed")
        }
        
        guard try Bcrypt.verify(userRequest.password, created: userDB.password) else {
            throw Abort(.notFound, reason: "Authentification failed")
        }
        
        let payload = UserPayload(id: userDB.id!)
        let signer = JWTSigner.hs256(key: "MACLESUPERSECRETE")
        let jwToken = try signer.sign(payload)
        
        return AuthDTO(token: jwToken)
    }
    
    @Sendable
    func profile(req :Request) async throws -> UserDTO {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let userDB = try await User.find(payload.id, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        return userDB.toDTO()
    }
}



struct AuthDTO: Content {
    let token: String
}

