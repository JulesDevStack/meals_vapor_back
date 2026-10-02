//
//  User.swift
//  project
//
//  Created by apprenant102 on 29/09/2026.
//

import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema: String = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "role")
    var role: String
    
    @Field(key: "created_at")
    var createdAt: Date
    
    @Children(for: \.$user)
    var reservations: [Reservation]
    
    init() {}
    
    init(id: UUID? = nil, name: String, password: String, email: String, role: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.password = password
        self.email = email
        self.role = role
        self.createdAt = createdAt
    }
}

extension User {
    func toDTO() -> UserDTO {
        return UserDTO(
            id: id,
            name: name,
            email: email,
            role: role,
            createdAt: createdAt
        )
    }
}

